import FinanceCore
import Foundation

/// A transaction paired with its normalized merchant, category prediction, and extracted features.
/// `isUserCorrected` is true when the prediction was overridden by a stored `UserCorrection`.
public struct AnalyzedTransaction: Sendable {
    /// The original transaction from the ledger.
    public let transaction: Transaction
    /// Normalized merchant resolved from the transaction description.
    public let merchantCandidate: MerchantCandidate
    /// Category assigned by the intelligence pipeline (rules, ML, or user correction).
    public let categoryPrediction: CategoryPrediction
    /// Feature vector extracted for ML inference and rule evaluation.
    public let features: TransactionFeatures
    /// True when the category was set by a stored user correction rather than the ML pipeline.
    public let isUserCorrected: Bool

    public init(
        transaction: Transaction,
        merchantCandidate: MerchantCandidate,
        categoryPrediction: CategoryPrediction,
        features: TransactionFeatures,
        isUserCorrected: Bool
    ) {
        self.transaction = transaction
        self.merchantCandidate = merchantCandidate
        self.categoryPrediction = categoryPrediction
        self.features = features
        self.isUserCorrected = isUserCorrected
    }
}
