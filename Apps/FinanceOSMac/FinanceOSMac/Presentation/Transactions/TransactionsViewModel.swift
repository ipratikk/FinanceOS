import FinanceCore
import FinanceOSAPI
import Foundation
import Observation

@MainActor
@Observable
final class TransactionsViewModel: AsyncLoadable, DeletableViewModel {
    private let graphQLClient: ApolloGraphQLClient

    var transactionRows: [TransactionRow] = []
    var listState = TransactionListState()
    var isLoading = false
    var deleteError: String?

    // Recalculation state
    var isRecalculating = false
    var recalculationResult: RecalculationResult?

    private var rawTransactions: [Transaction] = []
    private var cachedLedgers: [Ledger] = []

    var sections: [TransactionSection] {
        listState.sections(from: transactionRows)
    }

    init(graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
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
    }
}

// MARK: - Row Building

private extension TransactionsViewModel {
    func makeRows(
        transactions: [Transaction],
        results: [UUID: Never] = [:],
        ledgers: [Ledger]? = nil
    ) -> [TransactionRow] {
        let ledgersByID = Dictionary(uniqueKeysWithValues: (ledgers ?? cachedLedgers).map { ($0.id, $0) })
        return transactions.map { transaction in
            let sourceName = transaction.ledgerId.flatMap { ledgersByID[$0] }?.displayName ?? "Unknown Source"
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
                merchantName: transaction.merchantName,
                categoryId: transaction.categoryId,
                isUserCorrected: false,
                sourceTransaction: transaction
            )
        }
    }
}
