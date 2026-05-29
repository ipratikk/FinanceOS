import FinanceCore
import FinanceUI
import Foundation

enum TimeRange: String, CaseIterable, Identifiable {
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "All"

    var id: String {
        rawValue
    }

    var months: Int? {
        switch self {
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .oneYear: return 12
        case .all: return nil
        }
    }

    var visibleDays: Int? {
        switch self {
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        case .all: return nil
        }
    }
}

@Observable @MainActor
class DashboardViewModel: AsyncLoadable {
    var currentTotals: SpendingTotals?
    var monthlySummaries: [MonthlySpendingSummary] = []
    var netWorthTimeSeries: [NetWorthPoint] = []
    var recentTransactions: [TransactionRow] = []
    var isLoading = false
    var error: String?
    var selectedTimeRange: TimeRange = .sixMonths
    var ledgers: [Ledger] = []

    var effectiveTotals: SpendingTotals? {
        if let totals = currentTotals, totals.transactionCount > 0 { return totals }
        guard let last = monthlySummaries.last else { return currentTotals }
        return SpendingTotals(totalDebit: last.totalDebit, totalCredit: last.totalCredit, transactionCount: 0)
    }

    var effectiveMonth: Date {
        if let totals = currentTotals, totals.transactionCount > 0 { return Date() }
        return monthlySummaries.last?.month ?? Date()
    }

    var currentNetWorth: Decimal {
        netWorthTimeSeries.last?.netWorth ?? 0
    }

    var netWorthMoMDelta: Double? {
        guard let latest = netWorthTimeSeries.last else { return nil }
        let calendar = Calendar.current
        guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: latest.timestamp) else { return nil }
        guard let prevPoint = netWorthTimeSeries.min(by: {
            abs($0.timestamp.timeIntervalSince(oneMonthAgo)) < abs($1.timestamp.timeIntervalSince(oneMonthAgo))
        }), prevPoint.netWorth != 0 else { return nil }
        let delta = (latest.netWorth - prevPoint.netWorth) / abs(prevPoint.netWorth)
        return (delta as NSDecimalNumber).doubleValue
    }

    // MARK: - Display Strings

    var currentNetWorthText: String {
        FormatterCache.formatCurrency(currentNetWorth, currencyCode: "INR")
    }

    var netWorthMoMDeltaText: String? {
        guard let delta = netWorthMoMDelta else { return nil }
        return delta >= 0 ? String(format: "+%.1f%%", delta * 100) : String(format: "%.1f%%", delta * 100)
    }

    var netWorthDeltaIsPositive: Bool {
        (netWorthMoMDelta ?? 0) >= 0
    }

    var inflowsText: String {
        FormatterCache.formatCurrency(minorUnits: effectiveTotals?.totalCredit ?? 0)
    }

    var outflowsText: String {
        FormatterCache.formatCurrency(minorUnits: effectiveTotals?.totalDebit ?? 0)
    }

    var netSavingsText: String {
        let net = max(0, (effectiveTotals?.totalCredit ?? 0) - (effectiveTotals?.totalDebit ?? 0))
        return FormatterCache.formatCurrency(minorUnits: net)
    }

    var transactionCountBadge: String {
        guard let count = effectiveTotals?.transactionCount, count > 0 else { return "" }
        return "\(count) Txns"
    }

    // MARK: - Dependencies

    private let spendingService: any SpendingServiceProtocol
    private let transactionRepository: any TransactionRepository
    private let ledgerRepository: any LedgerRepository

    init(
        spendingService: any SpendingServiceProtocol,
        transactionRepository: any TransactionRepository,
        ledgerRepository: any LedgerRepository
    ) {
        self.spendingService = spendingService
        self.transactionRepository = transactionRepository
        self.ledgerRepository = ledgerRepository
    }

    func load() async {
        await withLoading(onError: { [self] error in
            self.error = error.localizedDescription
            FinanceLogger.userInterface.logError("Dashboard load failed", caughtError: error, [:])
        }, {
            let months = selectedTimeRange.months
            async let totals = spendingService.currentMonthTotals()
            async let summaries = spendingService.monthlySummary(months: months)
            async let recent = spendingService.recentTransactions(limit: 6)
            async let nwSeries = spendingService.netWorthTimeSeries(months: months)
            async let fetchedLedgers = ledgerRepository.fetchLedgers()
            currentTotals = try await totals
            monthlySummaries = try await summaries
            recentTransactions = try await makeRecentRows(recent)
            netWorthTimeSeries = try await nwSeries
            ledgers = try await fetchedLedgers
        })
    }

    func setTimeRange(_ range: TimeRange) async {
        selectedTimeRange = range
        await load()
    }

    func updateOpeningBalance(ledgerId: UUID, balanceMinorUnits: Int64) async {
        do {
            try await ledgerRepository.updateOpeningBalance(id: ledgerId, balance: balanceMinorUnits)
            ledgers = try await ledgerRepository.fetchLedgers()
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func exportNetWorthCSV() -> String {
        let header = "Date,NetWorth"
        let rows = netWorthTimeSeries.map { point in
            "\(FormatterCache.iso8601.string(from: point.timestamp)),\(point.netWorth)"
        }
        return ([header] + rows).joined(separator: "\n")
    }

    // MARK: - Private Mapping

    private func makeRecentRows(_ transactions: [Transaction]) -> [TransactionRow] {
        transactions.map { txn in
            TransactionRow(
                id: txn.id,
                title: txn.description,
                subtitle: "",
                amountText: txn.amountMinorUnits.formattedAsAmount(
                    currencyCode: txn.currencyCode,
                    transactionType: txn.transactionType
                ),
                amountMinorUnits: abs(txn.amountMinorUnits),
                transactionType: txn.transactionType,
                postedAt: txn.postedAt,
                merchantName: txn.merchantName,
                categoryId: txn.categoryId,
                sourceTransaction: txn
            )
        }
    }
}
