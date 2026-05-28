import Foundation

public struct CorrectionInput: Sendable {
    public let transactionId: UUID
    public let originalCategory: String?
    public let correctedCategory: String
    public let originalMerchant: String?
    public let correctedMerchant: String?
    public let originalConfidence: Double?
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

    public func correction(for transactionId: UUID) -> UserCorrection? {
        corrections[transactionId]
    }

    public func exportTrainingEligible() -> [UserCorrection] {
        corrections.values
            .filter(\.isTrainingEligible)
            .sorted { $0.timestamp < $1.timestamp }
    }

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
