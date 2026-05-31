import Foundation

/// Detects recurring payment patterns from a corpus of transactions.
public struct RecurringDetector: Sendable {
    private let analyzer: PatternAnalyzer
    private let schedule: ScheduleInference

    public init() {
        analyzer = PatternAnalyzer()
        schedule = ScheduleInference()
    }

    public struct DetectionInput: Sendable {
        public let transactionId: UUID
        public let merchantKey: String
        public let personId: String?
        public let amountMinorUnits: Int64
        public let postedAt: Date
        public let categoryId: String
        public let intentId: String

        public init(
            transactionId: UUID,
            merchantKey: String,
            personId: String? = nil,
            amountMinorUnits: Int64,
            postedAt: Date,
            categoryId: String,
            intentId: String
        ) {
            self.transactionId = transactionId
            self.merchantKey = merchantKey
            self.personId = personId
            self.amountMinorUnits = amountMinorUnits
            self.postedAt = postedAt
            self.categoryId = categoryId
            self.intentId = intentId
        }
    }

    public func detect(from transactions: [DetectionInput]) -> [RecurringPattern] {
        Dictionary(grouping: transactions) { $0.merchantKey }
            .compactMap { key, group in group.count >= 2 ? detectPattern(merchantKey: key, group: group) : nil }
            .sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Private

    private func detectPattern(merchantKey: String, group: [DetectionInput]) -> RecurringPattern? {
        let dates = group.map(\.postedAt).sorted()
        guard let (cadence, confidence) = analyzer.analyzeCadence(dates: dates),
              cadence != .irregular || confidence >= 0.5 else { return nil }

        let amounts = group.map(\.amountMinorUnits)
        let avg = amounts.reduce(0, +) / Int64(amounts.count)
        let variance = avg > 0
            ? amounts.map { Double(abs($0 - avg)) / Double(avg) }.reduce(0, +) / Double(amounts.count)
            : 0.0
        let dayHint = cadence == .monthly ? analyzer.dayOfMonthHint(from: dates) : nil
        let mostCommon = group.max { a, b in
            group.count(where: { $0.categoryId == a.categoryId }) <
                group.count(where: { $0.categoryId == b.categoryId })
        }

        return RecurringPattern(
            merchantKey: merchantKey,
            personId: group.first?.personId,
            categoryId: mostCommon?.categoryId ?? "transfers",
            intentId: mostCommon?.intentId ?? "unknown",
            cadence: cadence,
            averageAmountMinorUnits: avg,
            amountVariancePercent: variance,
            dayOfMonthHint: dayHint,
            confidence: confidence,
            occurrenceCount: group.count,
            lastSeenAt: dates.last ?? Date()
        )
    }
}
