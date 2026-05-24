import FinanceCore
import Foundation

@Observable @MainActor
class DashboardViewModel {
    var currentTotals: SpendingTotals?
    var monthlySummaries: [MonthlySpendingSummary] = []
    var recentTransactions: [Transaction] = []
    var isLoading = false
    var error: String?

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

            currentTotals = try await totals
            monthlySummaries = try await summaries
            recentTransactions = try await recent
        } catch {
            self.error = error.localizedDescription
            FinanceLogger.userInterface.logError("Dashboard load failed", caughtError: error, [:])
        }
    }
}
