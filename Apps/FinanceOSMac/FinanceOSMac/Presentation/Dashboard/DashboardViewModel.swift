import FinanceCore
import Foundation

@Observable @MainActor
class DashboardViewModel {
    var currentTotals: SpendingTotals?
    var monthlySummaries: [MonthlySpendingSummary] = []
    var netWorthTimeSeries: [NetWorthPoint] = []
    var recentTransactions: [Transaction] = []
    var chartHoverState: ChartHoverState = .idle
    var isLoading = false
    var error: String?

    var monthlySpendingPoints: [MonthlySpendingPoint] {
        monthlySummaries
            .sorted { $0.month < $1.month }
            .map { MonthlySpendingPoint(month: $0.month, spending: Decimal($0.totalDebit) / 100) }
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
