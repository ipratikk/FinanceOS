import FinanceCore
import Foundation

enum TimeRange: String, CaseIterable, Identifiable {
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "All"

    var id: String {
        rawValue
    }

    var months: Int {
        switch self {
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .oneYear: return 12
        case .all: return 120
        }
    }

    var visibleDays: Int {
        switch self {
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        case .all: return 3650
        }
    }
}

@Observable @MainActor
class DashboardViewModel {
    var currentTotals: SpendingTotals?
    var monthlySummaries: [MonthlySpendingSummary] = []
    var netWorthTimeSeries: [NetWorthPoint] = []
    var recentTransactions: [Transaction] = []
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
        isLoading = true
        defer { isLoading = false }

        do {
            let months = selectedTimeRange.months
            async let totals = spendingService.currentMonthTotals()
            async let summaries = spendingService.monthlySummary(months: months)
            async let recent = spendingService.recentTransactions(limit: 5)
            async let nwSeries = spendingService.netWorthTimeSeries(months: months)
            async let fetchedLedgers = ledgerRepository.fetchLedgers()

            currentTotals = try await totals
            monthlySummaries = try await summaries
            recentTransactions = try await recent
            netWorthTimeSeries = try await nwSeries
            ledgers = try await fetchedLedgers
        } catch {
            self.error = error.localizedDescription
            FinanceLogger.userInterface.logError("Dashboard load failed", caughtError: error, [:])
        }
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
        let formatter = ISO8601DateFormatter()
        let rows = netWorthTimeSeries.map { point in
            "\(formatter.string(from: point.timestamp)),\(point.netWorth)"
        }
        return ([header] + rows).joined(separator: "\n")
    }
}
