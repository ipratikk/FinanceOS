import Foundation

/// Value type used to record a new user correction without exposing `UserCorrection`'s internal init.
public struct CorrectionInput: Sendable {
    /// The transaction being corrected.
    public let transactionId: UUID
    /// Category ID that the model originally predicted. Nil when not previously categorized.
    public let originalCategory: String?
    /// Category ID explicitly chosen by the user.
    public let correctedCategory: String
    /// Merchant name before the correction. Nil when not previously resolved.
    public let originalMerchant: String?
    /// Merchant name explicitly set by the user. Nil when only the category changed.
    public let correctedMerchant: String?
    /// Model confidence for the prediction being overridden. Nil when not available.
    public let originalConfidence: Double?
    /// Model version that made the original prediction. Nil when not available.
    public let modelVersion: String?

    public init(
        transactionId: UUID,
        originalCategory: String?,
        correctedCategory: String,
        originalMerchant: String?,
        correctedMerchant: String?,
        originalConfidence: Double?,
        modelVersion: String?
    ) {
        self.transactionId = transactionId
        self.originalCategory = originalCategory
        self.correctedCategory = correctedCategory
        self.originalMerchant = originalMerchant
        self.correctedMerchant = correctedMerchant
        self.originalConfidence = originalConfidence
        self.modelVersion = modelVersion
    }
}

/// Persists user category/merchant corrections locally as JSON.
/// Thread-safe via actor isolation.
public actor UserCorrectionStore {
    private var corrections: [UUID: UserCorrection] = [:]
    private let storageURL: URL

    public init(storageURL: URL) {
        self.storageURL = storageURL
        corrections = Self.loadFromDisk(at: storageURL)
    }

    /// Persists a new correction, overwriting any existing correction for the same transaction.
    public func record(_ input: CorrectionInput) throws {
        let correction = UserCorrection(
            transactionId: input.transactionId,
            originalCategory: input.originalCategory,
            correctedCategory: input.correctedCategory,
            originalMerchant: input.originalMerchant,
            correctedMerchant: input.correctedMerchant,
            originalConfidence: input.originalConfidence,
            modelVersion: input.modelVersion,
            isTrainingEligible: true
        )
        corrections[input.transactionId] = correction
        try saveToDisk()
    }

    /// Returns the stored correction for `transactionId`, or nil when none exists.
    public func correction(for transactionId: UUID) -> UserCorrection? {
        corrections[transactionId]
    }

    /// Returns all corrections as a dictionary — single actor hop for batch operations.
    public func allCorrections() -> [UUID: UserCorrection] {
        corrections
    }

    /// Returns all training-eligible corrections sorted chronologically for model retraining pipelines.
    public func exportTrainingEligible() -> [UserCorrection] {
        corrections.values
            .filter(\.isTrainingEligible)
            .sorted { $0.timestamp < $1.timestamp }
    }

    /// Removes the correction for `transactionId` and persists the change. No-op when none exists.
    public func removeCorrection(for transactionId: UUID) throws {
        corrections.removeValue(forKey: transactionId)
        try saveToDisk()
    }
}

// MARK: - Disk Persistence

private extension UserCorrectionStore {
    func saveToDisk() throws {
        let list = Array(corrections.values)
        let data = try JSONEncoder().encode(list)
        try data.write(to: storageURL, options: .atomic)
    }

    static func loadFromDisk(at url: URL) -> [UUID: UserCorrection] {
        guard let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([UserCorrection].self, from: data)
        else { return [:] }
        return Dictionary(uniqueKeysWithValues: list.map { ($0.transactionId, $0) })
    }
}
