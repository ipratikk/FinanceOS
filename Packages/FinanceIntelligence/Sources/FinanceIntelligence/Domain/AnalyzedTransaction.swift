import FinanceCore
import Foundation

public struct AnalyzedTransaction: Sendable {
    public let transaction: Transaction
    public let merchantCandidate: MerchantCandidate
    public let categoryPrediction: CategoryPrediction
    public let features: TransactionFeatures
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
