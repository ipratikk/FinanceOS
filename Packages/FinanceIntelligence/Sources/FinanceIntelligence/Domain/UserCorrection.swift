import Foundation

/// An explicit user override of a transaction's category and/or merchant name.
/// Stored by `UserCorrectionStore` and applied at highest priority during analysis.
public struct UserCorrection: Identifiable, Codable, Sendable {
    /// Stable unique identifier for this correction record.
    public let id: UUID
    /// The transaction this correction applies to.
    public let transactionId: UUID
    /// Category ID assigned by the model before the user corrected it. Nil if unknown.
    public let originalCategory: String?
    /// Category ID explicitly chosen by the user. Always a valid `CategoryTaxonomy` ID.
    public let correctedCategory: String
    /// Merchant name before the user corrected it. Nil if not previously resolved.
    public let originalMerchant: String?
    /// Merchant name explicitly set by the user. Nil when the user only changed the category.
    public let correctedMerchant: String?
    /// Confidence of the model prediction that was overridden. Nil if not captured.
    public let originalConfidence: Double?
    /// Version string of the model that made the original (wrong) prediction. Nil if not captured.
    public let modelVersion: String?
    /// When the user made this correction.
    public let timestamp: Date
    /// True when this correction may be fed back into the kNN training pipeline.
    public let isTrainingEligible: Bool

    init(
        transactionId: UUID,
        originalCategory: String?,
        correctedCategory: String,
        originalMerchant: String?,
        correctedMerchant: String?,
        originalConfidence: Double?,
        modelVersion: String?,
        isTrainingEligible: Bool
    ) {
        id = UUID()
        self.transactionId = transactionId
        self.originalCategory = originalCategory
        self.correctedCategory = correctedCategory
        self.originalMerchant = originalMerchant
        self.correctedMerchant = correctedMerchant
        self.originalConfidence = originalConfidence
        self.modelVersion = modelVersion
        timestamp = Date()
        self.isTrainingEligible = isTrainingEligible
    }
}
