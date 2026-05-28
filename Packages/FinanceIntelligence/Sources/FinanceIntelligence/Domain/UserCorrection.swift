import Foundation

public struct UserCorrection: Identifiable, Codable, Sendable {
    public let id: UUID
    public let transactionId: UUID
    public let originalCategory: String?
    public let correctedCategory: String
    public let originalMerchant: String?
    public let correctedMerchant: String?
    public let originalConfidence: Double?
    public let modelVersion: String?
    public let timestamp: Date
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
