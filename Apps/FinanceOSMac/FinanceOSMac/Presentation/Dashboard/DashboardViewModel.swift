import FinanceCore
import Foundation

@Observable @MainActor
class DashboardViewModel {
    var currentTotals: SpendingTotals?
    var monthlySummaries: [MonthlySpendingSummary] = []
    var netWorthTimeSeries: [NetWorthPoint] = []
    var recentTransactions: [Transaction] = []
    var isLoading = false
    var error: String?

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

    init(
        spendingService: any SpendingServiceProtocol,
        transactionRepository: any TransactionRepository
    ) {
        self.spendingService = spendingService
        self.transactionRepository = transactionRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let totals = spendingService.currentMonthTotals()
            async let summaries = spendingService.monthlySummary(months: 6)
            async let recent = spendingService.recentTransactions(limit: 5)
            async let nwSeries = spendingService.netWorthTimeSeries(months: 6)

            currentTotals = try await totals
            monthlySummaries = try await summaries
            recentTransactions = try await recent
            netWorthTimeSeries = try await nwSeries
        } catch {
            self.error = error.localizedDescription
            FinanceLogger.userInterface.logError("Dashboard load failed", caughtError: error, [:])
        }
    }
}
