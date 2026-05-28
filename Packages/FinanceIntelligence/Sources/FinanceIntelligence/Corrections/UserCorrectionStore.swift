import Foundation

/// Persists user category/merchant corrections locally as JSON.
/// Thread-safe via actor isolation.
public actor UserCorrectionStore {
    private var corrections: [UUID: UserCorrection] = [:]
    private let storageURL: URL

    public init(storageURL: URL) {
        self.storageURL = storageURL
        corrections = Self.loadFromDisk(at: storageURL)
    }

    public func record(
        transactionId: UUID,
        originalCategory: String?,
        correctedCategory: String,
        originalMerchant: String?,
        correctedMerchant: String?,
        originalConfidence: Double?,
        modelVersion: String?
    ) throws {
        let correction = UserCorrection(
            transactionId: transactionId,
            originalCategory: originalCategory,
            correctedCategory: correctedCategory,
            originalMerchant: originalMerchant,
            correctedMerchant: correctedMerchant,
            originalConfidence: originalConfidence,
            modelVersion: modelVersion,
            isTrainingEligible: true
        )
        corrections[transactionId] = correction
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
