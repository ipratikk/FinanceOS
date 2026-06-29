import FinanceCore
import FinanceIntelligence
import FinanceOSAPI
import SwiftUI

/// Runs background ML categorization on all uncategorized transactions.
/// Safe to call concurrently — an `isRunning` guard prevents overlapping passes.
actor CategorizationScheduler {
    private let graphQLClient: ApolloGraphQLClient
    private let intelligenceService: any TransactionIntelligenceService
    private var isRunning = false

    init(
        graphQLClient: ApolloGraphQLClient,
        intelligenceService: any TransactionIntelligenceService
    ) {
        self.graphQLClient = graphQLClient
        self.intelligenceService = intelligenceService
    }

    /// Categorizes uncategorized transactions, then post-processes the FULL enriched history.
    /// No-ops if already running or if there are no transactions.
    func run() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }
        do {
            let data = try await graphQLClient.fetch(
                query: GetTransactionsQuery(ledgerId: .none, filter: .none, limit: .none)
            )
            let all = data.transactions.map { mapTransaction($0) }
            guard !all.isEmpty else { return }

            // Enrich ALL in one pass: uncategorized get categoryId persisted via GraphQL mutation;
            // all are collected for postProcessBatch (needs full history for recurring detection).
            // Per-transaction error isolation — one failure does not abort the batch.
            var enriched: [EnrichedTransaction] = []
            enriched.reserveCapacity(all.count)
            for txn in all {
                do {
                    let result = try await intelligenceService.analyzeEnriched(txn, context: .empty)
                    let categoryId = result.categoryPrediction.categoryId
                    if !categoryId.isEmpty {
                        _ = try? await graphQLClient.perform(
                            mutation: RecategorizeMutation(
                                transactionId: txn.id.uuidString,
                                category: categoryId
                            )
                        )
                    }
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

    private nonisolated func mapTransaction(_ item: GetTransactionsQuery.Data.Transaction) -> FinanceCore.Transaction {
        let rawAmount = Int64(item.amount * 100)
        let amountMinorUnits = abs(rawAmount)
        let transactionType: TransactionType = item.amount < 0 ? .debit : .credit
        return Transaction(
            id: UUID(uuidString: item.id) ?? UUID(),
            ledgerId: UUID(uuidString: item.ledger.id),
            postedAt: parseDate(item.date),
            description: item.narration,
            amountMinorUnits: amountMinorUnits,
            currencyCode: "INR",
            transactionType: transactionType,
            sourceFingerprint: item.sourceFingerprint,
            categoryId: item.category,
            merchantName: item.merchant
        )
    }

    private nonisolated func parseDate(_ string: String) -> Date {
        let iso8601Full = ISO8601DateFormatter()
        iso8601Full.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Full.date(from: string) { return date }
        let iso8601Short = ISO8601DateFormatter()
        iso8601Short.formatOptions = [.withInternetDateTime]
        return iso8601Short.date(from: string) ?? Date()
    }
}

extension EnvironmentValues {
    @Entry var categorizationScheduler: CategorizationScheduler?
}
