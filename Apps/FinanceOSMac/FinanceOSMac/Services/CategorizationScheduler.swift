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

    /// Categorizes all uncategorized transactions, persists results, then runs post-processing
    /// (knowledge graph, recurring detection, relationship inference) on the full enriched batch.
    /// No-ops if already running or if nothing needs categorizing.
    func run() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }
        do {
            let all = try await transactionRepository.fetchTransactions()
            let uncategorized = all.filter { $0.categoryId == nil }
            guard !uncategorized.isEmpty else { return }

            // analyzeEnriched gives categorization + intent + description in one pass
            var enriched: [EnrichedTransaction] = []
            enriched.reserveCapacity(uncategorized.count)
            for txn in uncategorized {
                let result = try await intelligenceService.analyzeEnriched(txn, context: .empty)
                try? await transactionRepository.updateIntelligence(
                    id: txn.id,
                    categoryId: result.categoryPrediction.categoryId,
                    merchantName: result.merchantCandidate.canonicalName
                )
                enriched.append(result)
            }

            // Post-process: graph + recurring (any cadence, ≥2 occurrences) + relationships
            await intelligenceService.postProcessBatch(enriched: enriched, onStageChange: nil)
        } catch {
            FinanceLogger.transactions.logError("Background categorization failed", caughtError: error, [:])
        }
    }
}

extension EnvironmentValues {
    @Entry var categorizationScheduler: CategorizationScheduler?
}
