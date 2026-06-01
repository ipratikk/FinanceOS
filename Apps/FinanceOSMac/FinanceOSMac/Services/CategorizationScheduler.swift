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

    /// Categorizes uncategorized transactions, then post-processes the FULL enriched history.
    /// No-ops if already running or if there are no transactions.
    func run() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }
        do {
            let all = try await transactionRepository.fetchTransactions()
            guard !all.isEmpty else { return }

            // Enrich ALL in one pass: uncategorized get categoryId persisted;
            // all are collected for postProcessBatch (needs full history for recurring detection).
            // Per-transaction error isolation — one failure does not abort the batch.
            var enriched: [EnrichedTransaction] = []
            enriched.reserveCapacity(all.count)
            for txn in all {
                do {
                    let result = try await intelligenceService.analyzeEnriched(txn, context: .empty)
                    try? await transactionRepository.updateEnrichmentProvenance(
                        id: txn.id,
                        EnrichmentProvenance(
                            categoryId: result.categoryPrediction.categoryId,
                            merchantName: result.merchantCandidate.canonicalName,
                            intentId: result.intentPrediction.intent.rawValue,
                            resolvedPersonId: result.resolvedEntities?.personId?.uuidString,
                            intelligenceSource: result.categoryPrediction.source.rawValue,
                            intelligenceModelVersion: result.categoryPrediction.modelVersion,
                            intelligenceConfigVersion: result.categoryPrediction.configVersion
                        )
                    )
                    enriched.append(result)
                } catch {
                    FinanceLogger.transactions.logError(
                        "Categorization skipped for transaction", caughtError: error, [:]
                    )
                }
            }

            guard !enriched.isEmpty else { return }
            await intelligenceService.postProcessBatch(enriched: enriched, onStageChange: nil)
        } catch {
            FinanceLogger.transactions.logError("Background categorization failed", caughtError: error, [:])
        }
    }
}

extension EnvironmentValues {
    @Entry var categorizationScheduler: CategorizationScheduler?
}
