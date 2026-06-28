import FinanceCore
import FinanceIntelligence
import FinanceOSAPI
import Foundation
import Observation

@MainActor
@Observable
final class TransactionsViewModel: AsyncLoadable, DeletableViewModel {
    private let graphQLClient: ApolloGraphQLClient
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

    // Recalculation state
    var isRecalculating = false
    var recalculationResult: RecalculationResult?

    private var rawTransactions: [Transaction] = []
    private var cachedLedgers: [Ledger] = []

    var sections: [TransactionSection] {
        listState.sections(from: transactionRows)
    }

    init(
        graphQLClient: ApolloGraphQLClient,
        intelligenceService: (any TransactionIntelligenceService)? = nil
    ) {
        self.graphQLClient = graphQLClient
        self.intelligenceService = intelligenceService
    }

    func loadTransactions() async {
        await withLoading(onError: { error in
            FinanceLogger.userInterface.logError("Failed to load transactions", caughtError: error, [:])
        }, {
            async let txnsQuery = graphQLClient.fetch(query: GetTransactionsQuery(
                ledgerId: .none,
                filter: .none,
                limit: .none
            ))
            async let ledgersQuery = graphQLClient.fetch(query: GetLedgersQuery())
            let (txnsData, ledgersData) = try await (txnsQuery, ledgersQuery)
            rawTransactions = txnsData.transactions.map(GraphQLMappings.mapTransaction)
            cachedLedgers = ledgersData.ledgers.map(GraphQLMappings.mapLedger)
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

            let all = await MainActor.run { rawTransactions }
            pipelineTotal = all.count
            guard !Task.isCancelled else { return }

            let enriched = await runAnalyzingStage(service: service, transactions: all)
            guard !Task.isCancelled, !enriched.isEmpty else { return }

            // Stages 2–4: post-process with typed stage reporting
            await service.postProcessBatch(enriched: enriched) { stage in
                Task { @MainActor [weak self] in self?.applyPipelineStage(stage) }
            }

            // Reload rows with fresh data
            await loadTransactions()
        }
    }

    /// Stage 1: analyze every transaction (in-memory only; backend owns persistence).
    private func runAnalyzingStage(
        service: any TransactionIntelligenceService,
        transactions: [Transaction]
    ) async -> [EnrichedTransaction] {
        var enriched: [EnrichedTransaction] = []
        enriched.reserveCapacity(transactions.count)
        for txn in transactions {
            guard !Task.isCancelled else { return enriched }
            do {
                let result = try await service.analyzeEnriched(txn, context: .empty)
                enriched.append(result)
            } catch {
                FinanceLogger.userInterface.logError("Pipeline: skipped transaction", caughtError: error, [:])
            }
            pipelineProcessed += 1
        }
        return enriched
    }

    func cancelPipeline() {
        pipelineTask?.cancel()
        pipelineTask = nil
        isPipelineRunning = false
    }

    /// Validates accounting invariants on the in-memory transaction set and returns a summary.
    /// Checks: orphaned linkedTransactionId references, balance equations per ledger,
    /// and expense/income totals using TransactionFilter predicates.
    func runRecalculation() {
        guard !isRecalculating, !rawTransactions.isEmpty else { return }
        isRecalculating = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { isRecalculating = false }

            let transactions = rawTransactions
            let ledgers = cachedLedgers

            // Run validators off the main queue to avoid blocking UI
            let result = await Task.detached(priority: .userInitiated) {
                RecalculationResult.compute(transactions: transactions, ledgers: ledgers)
            }.value

            recalculationResult = result
        }
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
            _ = try await graphQLClient.perform(mutation: DeleteTransactionMutation(id: id.uuidString))
        }, onSuccess: loadTransactions)
    }

    /// Called when the user corrects a category. Updates memory, persists via GraphQL, trains kNN,
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

        // Persist via GraphQL — preserve merchantName so displayTitle stays stable (Bug 1 fix)
        do {
            _ = try await graphQLClient.perform(
                mutation: RecategorizeMutation(transactionId: transactionId.uuidString, category: correctedCategoryId)
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
