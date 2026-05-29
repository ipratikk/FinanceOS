import FinanceCore
import FinanceIntelligence
import SwiftUI

/// Runs background ML categorization on all uncategorized transactions.
/// Safe to call concurrently — an `isRunning` guard prevents overlapping passes.
actor CategorizationScheduler {
    private let transactionRepository: any TransactionRepository
    private let intelligenceService: any TransactionIntelligenceService
    private var isRunning = false

    init(
        transactionRepository: any TransactionRepository,
        intelligenceService: any TransactionIntelligenceService
    ) {
        self.transactionRepository = transactionRepository
        self.intelligenceService = intelligenceService
    }

    /// Fetches all uncategorized transactions, runs `analyzeBatch`, and persists results.
    /// No-ops if already running or if nothing needs categorizing.
    func run() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }
        do {
            let all = try await transactionRepository.fetchTransactions()
            let uncategorized = all.filter { $0.categoryId == nil }
            guard !uncategorized.isEmpty else { return }
            let results = try await intelligenceService.analyzeBatch(uncategorized, context: .empty)
            for result in results {
                try? await transactionRepository.updateIntelligence(
                    id: result.transaction.id,
                    categoryId: result.categoryPrediction.categoryId,
                    merchantName: result.merchantCandidate.canonicalName
                )
            }
        } catch {
            FinanceLogger.transactions.logError("Background categorization failed", caughtError: error, [:])
        }
    }
}

extension EnvironmentValues {
    @Entry var categorizationScheduler: CategorizationScheduler?
}
