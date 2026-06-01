import FinanceCore
import Foundation
import GRDB

/// Caller-supplied context that the intelligence pipeline uses to improve predictions.
/// Providing `ledgerKind` and `institution` lets the feature extractor add stronger signals.
public struct IntelligenceContext: Sendable {
    /// The ledger type the transaction belongs to (e.g. `.savings`, `.credit`).
    public let ledgerKind: LedgerKind?
    /// The financial institution name (e.g. `"HDFC"`, `"ICICI"`).
    public let institution: String?

    /// Context with no supplementary information — safe to use when context is unavailable.
    public static let empty = IntelligenceContext(ledgerKind: nil, institution: nil)

    public init(ledgerKind: LedgerKind?, institution: String?) {
        self.ledgerKind = ledgerKind
        self.institution = institution
    }
}

/// Contract for the on-device transaction intelligence system.
/// Conforming types orchestrate merchant normalization, categorization, and personalized learning.
public protocol TransactionIntelligenceService: Sendable {
    /// Analyzes a single transaction and returns a fully resolved `AnalyzedTransaction`.
    func analyze(_ transaction: Transaction, context: IntelligenceContext) async throws -> AnalyzedTransaction
    /// Analyzes a batch of transactions efficiently, minimizing actor hops over the batch.
    func analyzeBatch(
        _ transactions: [Transaction],
        context: IntelligenceContext
    ) async throws -> [AnalyzedTransaction]
    /// Generates spending insights (recurring charges, spikes, anomalies) over the given transactions.
    func generateInsights(for transactions: [Transaction]) async throws -> [TransactionInsight]

    /// Record a user correction and immediately learn from it for future predictions.
    /// Call this whenever the user changes a transaction's category or merchant.
    func learn(
        transaction: Transaction,
        correctedCategoryId: String,
        correctedMerchant: String?,
        previousPrediction: CategoryPrediction?
    ) async throws

    /// Analyzes a transaction and returns an `EnrichedTransaction` including intent,
    /// resolved entities, and a human-readable description from FallbackGenerator.
    /// Prefer this over `analyze()` for new call sites.
    func analyzeEnriched(
        _ transaction: Transaction,
        context: IntelligenceContext
    ) async throws -> EnrichedTransaction

    /// Run background post-processing on the FULL enriched corpus.
    /// Stages: .graph → .patterns → .relationships → .complete.
    /// onStageChange is called at each transition for progress UI and audit logging.
    func postProcessBatch(
        enriched: [EnrichedTransaction],
        onStageChange: (@Sendable (PostProcessingStage) -> Void)?
    ) async

    /// Bulk-trains the on-device PersonalizedClassifier from (rawDescription, categoryId) pairs.
    /// Call after import+categorization to encode all transaction knowledge into the ML model
    /// so keyword rules can eventually be removed. Uses CoreML MLUpdateTask on-device.
    func trainClassifier(examples: [(text: String, categoryId: String)]) async throws

    /// Evaluates the PersonalizedClassifier against labeled examples.
    /// Returns nil when PersonalizedClassifier is unavailable.
    func evaluateClassifier(examples: [(text: String, categoryId: String)]) async -> ClassifierEvalResult?
}
