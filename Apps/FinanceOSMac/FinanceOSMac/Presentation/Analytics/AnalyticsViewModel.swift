import FinanceCore
import Foundation

@Observable @MainActor
class AnalyticsViewModel {
    var monthlySummaries: [MonthlySpendingSummary] = []
    var topMerchants: [(String, Int64)] = []
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
            async let summaries = spendingService.monthlySummary(months: 6)

            monthlySummaries = try await summaries

            let allTransactions = try await transactionRepository.fetchTransactions()
            topMerchants = aggregateTopMerchants(from: allTransactions)
        } catch {
            self.error = error.localizedDescription
            FinanceLogger.ui.logError("Analytics load failed", caughtError: error, [:])
        }
    }

    private func aggregateTopMerchants(from transactions: [Transaction]) -> [(String, Int64)] {
        var merchantTotals: [String: Int64] = [:]

        for txn in transactions {
            guard txn.amountMinorUnits < 0 else { continue }
            merchantTotals[txn.description, default: 0] -= txn.amountMinorUnits
        }

        return merchantTotals
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { ($0.key, $0.value) }
    }
}
