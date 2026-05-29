import FinanceCore
import Foundation

/// Stateless insight engine. All methods are pure computations over [Transaction].
public struct SpendingInsightEngine: Sendable {
    private static let calendar = Calendar(identifier: .gregorian)
    private let normalizer: MerchantNormalizer

    public init(normalizer: MerchantNormalizer = MerchantNormalizer()) {
        self.normalizer = normalizer
    }

    /// Runs all insight detectors over `transactions` and returns the combined results.
    public func generate(for transactions: [Transaction]) -> [TransactionInsight] {
        var insights: [TransactionInsight] = []
        insights += detectRecurring(in: transactions)
        insights += detectSpikes(in: transactions)
        insights += detectUnusuallyLarge(in: transactions)
        return insights
    }
}

// MARK: - Recurring Detection

extension SpendingInsightEngine {
    /// Detects recurring and subscription-like charges by grouping debits by merchant
    /// and checking whether intervals cluster around 7 days (weekly) or 30 days (monthly).
    func detectRecurring(in transactions: [Transaction]) -> [TransactionInsight] {
        let groups = groupByMerchant(transactions)
        var insights: [TransactionInsight] = []

        for (merchant, txns) in groups where txns.count >= 3 {
            let sorted = txns.sorted { $0.postedAt < $1.postedAt }
            let intervals = zip(sorted.dropFirst(), sorted).map {
                Self.calendar.dateComponents([.day], from: $1.postedAt, to: $0.postedAt).day ?? 0
            }
            guard let insight = evaluateIntervals(
                intervals: intervals,
                merchant: merchant,
                transactions: sorted
            ) else { continue }
            insights.append(insight)
        }
        return insights
    }

    private func evaluateIntervals(
        intervals: [Int],
        merchant: String,
        transactions: [Transaction]
    ) -> TransactionInsight? {
        let median = medianInt(intervals)
        let ids = transactions.map(\.id.uuidString)

        if (25 ... 35).contains(median) {
            let amounts = transactions.map { Double($0.amountMinorUnits) }
            let isConsistentAmount = coefficientOfVariation(amounts) < 0.15
            let kind: InsightKind = isConsistentAmount ? .subscriptionDetected : .recurringTransaction
            let title = isConsistentAmount
                ? "Likely subscription: \(merchant)"
                : "Recurring charge: \(merchant)"
            let explanation = isConsistentAmount
                ? "Monthly charge of ~\(formatMinorUnits(transactions.last?.amountMinorUnits ?? 0)). Consistent."
                : "Recurring monthly charge from \(merchant)."
            return TransactionInsight(
                kind: kind, title: title, explanation: explanation,
                affectedTransactionIDs: ids, confidence: 0.85, severity: .info
            )
        }
        if (6 ... 8).contains(median) {
            return TransactionInsight(
                kind: .recurringTransaction,
                title: "Weekly charge: \(merchant)",
                explanation: "Charge appears roughly every week.",
                affectedTransactionIDs: ids, confidence: 0.75, severity: .info
            )
        }
        return nil
    }
}

// MARK: - Spending Spike Detection

extension SpendingInsightEngine {
    /// Detects months where total debit spending exceeds the historical mean by more than 2 standard deviations.
    /// Requires at least 3 months of data; returns an empty array when insufficient history is available.
    func detectSpikes(in transactions: [Transaction]) -> [TransactionInsight] {
        let byMonth = groupByMonth(transactions)
        guard byMonth.count >= 3 else { return [] }
        let sorted = byMonth.keys.sorted()
        guard let latestMonth = sorted.last else { return [] }
        let historicalMonths = sorted.dropLast()

        let historicalSpend = historicalMonths.compactMap { byMonth[$0] }
            .map { Double($0.reduce(0) { $0 + $1.amountMinorUnits }) }
        let latestSpend = Double(byMonth[latestMonth]?.reduce(0) { $0 + $1.amountMinorUnits } ?? 0)
        let latestTxns = byMonth[latestMonth] ?? []

        guard let insight = buildSpikeInsight(
            latestSpend: latestSpend,
            historicalSpend: historicalSpend,
            latestTxns: latestTxns
        ) else { return [] }
        return [insight]
    }

    private func buildSpikeInsight(
        latestSpend: Double,
        historicalSpend: [Double],
        latestTxns: [Transaction]
    ) -> TransactionInsight? {
        guard historicalSpend.count >= 2 else { return nil }
        let mean = historicalSpend.reduce(0, +) / Double(historicalSpend.count)
        let variance = historicalSpend.map { pow($0 - mean, 2) }.reduce(0, +) / Double(historicalSpend.count)
        let stdDev = sqrt(variance)
        guard stdDev > 0, latestSpend > mean + 2 * stdDev else { return nil }

        let pctOver = ((latestSpend - mean) / mean * 100).rounded()
        let ids = latestTxns.map(\.id.uuidString)
        return TransactionInsight(
            kind: .spendingSpike,
            title: "Spending spike this month",
            explanation: "Spending is \(Int(pctOver))% above your recent average.",
            affectedTransactionIDs: ids, confidence: 0.8, severity: .warning
        )
    }
}

// MARK: - Unusually Large Transaction Detection

extension SpendingInsightEngine {
    /// Flags individual debit transactions that exceed the mean by more than 3 standard deviations.
    /// Credits (salary, income) are excluded — only debits are analyzed.
    func detectUnusuallyLarge(in transactions: [Transaction]) -> [TransactionInsight] {
        // Only analyze debits — credits (salary, income) have naturally large amounts and are not anomalies.
        let debits = transactions.filter { $0.transactionType == .debit }
        guard debits.count >= 5 else { return [] }
        let amounts = debits.map { Double($0.amountMinorUnits) }.sorted()
        let mean = amounts.reduce(0, +) / Double(amounts.count)
        let variance = amounts.map { pow($0 - mean, 2) }.reduce(0, +) / Double(amounts.count)
        let stdDev = sqrt(variance)
        let threshold = mean + 3 * stdDev

        return debits.compactMap { txn in
            guard Double(txn.amountMinorUnits) > threshold else { return nil }
            return TransactionInsight(
                kind: .unusuallyLargeTransaction,
                title: "Unusually large transaction",
                explanation: "\(txn.description): \(formatMinorUnits(txn.amountMinorUnits)) — above average.",
                affectedTransactionIDs: [txn.id.uuidString],
                confidence: 0.78, severity: .alert
            )
        }
    }
}

// MARK: - Private Utilities

private extension SpendingInsightEngine {
    func groupByMerchant(_ transactions: [Transaction]) -> [String: [Transaction]] {
        var result: [String: [Transaction]] = [:]
        for txn in transactions where txn.transactionType == .debit {
            let key = normalizer.normalize(txn.description).canonicalName
            result[key, default: []].append(txn)
        }
        return result
    }

    func groupByMonth(_ transactions: [Transaction]) -> [Date: [Transaction]] {
        var result: [Date: [Transaction]] = [:]
        for txn in transactions where txn.transactionType == .debit {
            guard let month = Self.calendar.date(
                from: Self.calendar.dateComponents([.year, .month], from: txn.postedAt)
            ) else { continue }
            result[month, default: []].append(txn)
        }
        return result
    }

    func medianInt(_ values: [Int]) -> Int {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        let mid = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }

    func coefficientOfVariation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        guard mean > 0 else { return 0 }
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance) / mean
    }

    func formatMinorUnits(_ minorUnits: Int64) -> String {
        let major = Double(minorUnits) / 100.0
        return String(format: "%.2f", major)
    }
}
