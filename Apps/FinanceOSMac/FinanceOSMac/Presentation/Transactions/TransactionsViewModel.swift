import FinanceCore
import FinanceIntelligence
import Foundation
import Observation

@MainActor
@Observable
final class TransactionsViewModel: AsyncLoadable, DeletableViewModel {
    private let transactionRepository: TransactionRepository
    private let ledgerRepository: LedgerRepository
    private let intelligenceService: (any TransactionIntelligenceService)?

    var transactionRows: [TransactionRow] = []
    var listState = TransactionListState()
    var isLoading = false
    var isAnalyzing = false
    var deleteError: String?

    // Pipeline state
    var isPipelineRunning = false
    var pipelineProcessed = 0
    var pipelineTotal = 0
    var pipelineStage: PipelineStage = .analyzing
    private var pipelineTask: Task<Void, Never>?

    private var rawTransactions: [Transaction] = []
    private var cachedLedgers: [Ledger] = []

    var sections: [TransactionSection] {
        listState.sections(from: transactionRows)
    }

    init(
        transactionRepository: TransactionRepository,
        ledgerRepository: LedgerRepository,
        intelligenceService: (any TransactionIntelligenceService)? = nil
    ) {
        self.transactionRepository = transactionRepository
        self.ledgerRepository = ledgerRepository
        self.intelligenceService = intelligenceService
    }

    func loadTransactions() async {
        await withLoading(onError: { error in
            FinanceLogger.userInterface.logError("Failed to load transactions", caughtError: error, [:])
        }, {
            rawTransactions = try await transactionRepository.fetchTransactions()
            cachedLedgers = try await ledgerRepository.fetchLedgers()
            transactionRows = makeRows(transactions: rawTransactions, results: [:])
            listState.updateAvailableYears(from: transactionRows)
        })
        Task.detached(priority: .background) { [weak self] in
            await self?.analyzeUncategorized()
        }
    }

    /// Run the full intelligence pipeline on ALL transactions (categorization + graph + recurring + relationships).
    func runIntelligencePipeline() {
        guard !isPipelineRunning, let service = intelligenceService else { return }
        pipelineTask?.cancel()
        pipelineTask = Task { @MainActor in
            isPipelineRunning = true
            pipelineProcessed = 0
            pipelineStage = .analyzing
            defer { isPipelineRunning = false }

            do {
                let all = try await transactionRepository.fetchTransactions()
                pipelineTotal = all.count
                guard !Task.isCancelled else { return }

                // Stage 1: Analyze all transactions
                var enriched: [EnrichedTransaction] = []
                enriched.reserveCapacity(all.count)
                for txn in all {
                    guard !Task.isCancelled else { return }
                    do {
                        let result = try await service.analyzeEnriched(txn, context: .empty)
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
                        FinanceLogger.userInterface.logError(
                            "Pipeline: skipped transaction", caughtError: error, [:]
                        )
                    }
                    pipelineProcessed += 1
                }

                guard !Task.isCancelled, !enriched.isEmpty else { return }

                // Stages 2–4: post-process with typed stage reporting
                await service.postProcessBatch(enriched: enriched) { stage in
                    Task { @MainActor [weak self] in self?.applyPipelineStage(stage) }
                }

                // Reload rows with fresh data
                await loadTransactions()
            } catch {
                FinanceLogger.userInterface.logError("Intelligence pipeline failed", caughtError: error, [:])
            }
        }
    }

    func cancelPipeline() {
        pipelineTask?.cancel()
        pipelineTask = nil
        isPipelineRunning = false
    }

    private func applyPipelineStage(_ stage: PostProcessingStage) {
        switch stage {
        case .graph: pipelineStage = .graph
        case .patterns: pipelineStage = .patterns
        case .relationships: pipelineStage = .relationships
        case .complete: break
        }
    }

    func deleteTransaction(id: UUID) async {
        await performDelete({
            try await transactionRepository.delete(id: id)
        }, onSuccess: loadTransactions)
    }

    /// Called when the user corrects a category. Updates memory, persists to DB, trains kNN,
    /// then re-analyzes auto-categorized transactions so similar ones update immediately.
    func applyCorrection(transactionId: UUID, correctedCategoryId: String) async {
        guard let idx = transactionRows.firstIndex(where: { $0.id == transactionId }) else { return }
        let old = transactionRows[idx]

        // Update row in memory immediately — preserve existing merchantName (Bug 1 fix)
        transactionRows[idx] = TransactionRow(
            id: old.id, title: old.title, subtitle: old.subtitle,
            amountText: old.amountText, transactionType: old.transactionType,
            postedAt: old.postedAt, merchantName: old.merchantName,
            categoryId: correctedCategoryId, isUserCorrected: true,
            sourceTransaction: old.sourceTransaction
        )

        // Persist to DB — preserve merchantName so displayTitle stays stable (Bug 1 fix)
        do {
            try await transactionRepository.updateIntelligence(
                id: transactionId, categoryId: correctedCategoryId, merchantName: old.merchantName
            )
        } catch {
            FinanceLogger.userInterface.logError("Failed to persist correction", caughtError: error, [:])
        }

        // Train kNN on this correction so similar transactions benefit (Bug 2 fix)
        if let service = intelligenceService, let transaction = old.sourceTransaction {
            try? await service.learn(
                transaction: transaction,
                correctedCategoryId: correctedCategoryId,
                correctedMerchant: old.merchantName,
                previousPrediction: nil
            )
        }

        // Re-analyze auto-categorized transactions with updated kNN (Bug 2 fix)
        Task.detached(priority: .background) { [weak self] in
            await self?.reAnalyzeAutoCategorized()
        }
    }
}

// MARK: - Intelligence

private extension TransactionsViewModel {
    /// Re-analyze transactions already auto-categorized — called after user correction
    /// so the updated kNN applies to similar transactions immediately.
    func reAnalyzeAutoCategorized() async {
        guard let service = intelligenceService else { return }
        let (allTransactions, userCorrectedIds) = await MainActor.run {
            let corrected = Set(transactionRows.filter(\.isUserCorrected).map(\.id))
            return (rawTransactions, corrected)
        }
        // Re-analyze everything NOT manually corrected by the user
        let toReanalyze = allTransactions.filter { !userCorrectedIds.contains($0.id) }
        guard !toReanalyze.isEmpty else { return }
        await runAnalysis(service: service, transactions: toReanalyze)
    }

    func analyzeUncategorized() async {
        guard let service = intelligenceService else { return }
        let allTransactions = await MainActor.run { rawTransactions }
        let uncategorized = allTransactions.filter { $0.categoryId == nil }
        guard !uncategorized.isEmpty else { return }
        await runAnalysis(service: service, transactions: uncategorized)
    }

    func runAnalysis(service: any TransactionIntelligenceService, transactions: [Transaction]) async {
        let allTransactions = await MainActor.run { rawTransactions }
        await MainActor.run { isAnalyzing = true }
        do {
            let results = try await service.analyzeBatch(transactions, context: .empty)
            let byId = Dictionary(uniqueKeysWithValues: results.map { ($0.transaction.id, $0) })

            // Persist results with full provenance. isUserCorrectedMerchant protection
            // is enforced inside updateEnrichmentProvenance.
            let repo = await MainActor.run { transactionRepository }
            for result in results {
                try? await repo.updateEnrichmentProvenance(
                    id: result.transaction.id,
                    EnrichmentProvenance(
                        categoryId: result.categoryPrediction.categoryId,
                        merchantName: result.merchantCandidate.canonicalName,
                        intelligenceSource: result.categoryPrediction.source.rawValue,
                        intelligenceModelVersion: result.categoryPrediction.modelVersion,
                        intelligenceConfigVersion: result.categoryPrediction.configVersion
                    )
                )
            }

            let ledgers = await MainActor.run { cachedLedgers }
            let updated = makeRows(transactions: allTransactions, results: byId, ledgers: ledgers)
            await MainActor.run {
                // Preserve isUserCorrected flag — don't overwrite user corrections in the row list
                let correctedIds = Set(transactionRows.filter(\.isUserCorrected).map(\.id))
                transactionRows = updated.map { row in
                    guard correctedIds.contains(row.id),
                          let existing = transactionRows.first(where: { $0.id == row.id })
                    else { return row }
                    return existing
                }
                isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                FinanceLogger.userInterface.logError("Intelligence analysis failed", caughtError: error, [:])
                isAnalyzing = false
            }
        }
    }
}

// MARK: - Row Building

private extension TransactionsViewModel {
    func makeRows(
        transactions: [Transaction],
        results: [UUID: AnalyzedTransaction],
        ledgers: [Ledger]? = nil
    ) -> [TransactionRow] {
        let ledgersByID = Dictionary(uniqueKeysWithValues: (ledgers ?? cachedLedgers).map { ($0.id, $0) })
        return transactions.map { transaction in
            let sourceName = transaction.ledgerId.flatMap { ledgersByID[$0] }?.displayName ?? "Unknown Source"
            let analyzed = results[transaction.id]
            // Prefer fresh intelligence result; fall back to DB-cached values.
            let categoryId = analyzed?.categoryPrediction.categoryId ?? transaction.categoryId
            let merchantName = analyzed?.merchantCandidate.canonicalName ?? transaction.merchantName
            return TransactionRow(
                id: transaction.id,
                title: transaction.description,
                subtitle: sourceName,
                amountText: transaction.amountMinorUnits.formattedAsAmount(
                    currencyCode: transaction.currencyCode,
                    transactionType: transaction.transactionType
                ),
                amountMinorUnits: abs(transaction.amountMinorUnits),
                transactionType: transaction.transactionType,
                postedAt: transaction.postedAt,
                merchantName: merchantName,
                categoryId: categoryId,
                isUserCorrected: analyzed?.isUserCorrected ?? false,
                sourceTransaction: transaction
            )
        }
    }
}
