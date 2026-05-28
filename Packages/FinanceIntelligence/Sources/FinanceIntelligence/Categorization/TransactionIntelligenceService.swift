import FinanceCore
import Foundation

public struct IntelligenceContext: Sendable {
    public let ledgerKind: LedgerKind?
    public let institution: String?

    public static let empty = IntelligenceContext(ledgerKind: nil, institution: nil)

    public init(ledgerKind: LedgerKind?, institution: String?) {
        self.ledgerKind = ledgerKind
        self.institution = institution
    }
}

public protocol TransactionIntelligenceService: Sendable {
    func analyze(_ transaction: Transaction, context: IntelligenceContext) async throws -> AnalyzedTransaction
    func analyzeBatch(
        _ transactions: [Transaction],
        context: IntelligenceContext
    ) async throws -> [AnalyzedTransaction]
    func generateInsights(for transactions: [Transaction]) async throws -> [TransactionInsight]

    /// Record a user correction and immediately learn from it for future predictions.
    /// Call this whenever the user changes a transaction's category or merchant.
    func learn(
        transaction: Transaction,
        correctedCategoryId: String,
        correctedMerchant: String?,
        previousPrediction: CategoryPrediction?
    ) async throws
}
