import Foundation

public struct ModelMetadata: Codable, Sendable {
    public let modelVersion: String
    public let taxonomyVersion: String
    public let trainedAt: Date?
    public let trainingDataRows: Int?
    public let accuracy: Double?
    public let macroF1: Double?
    public let notes: String?

    public init(
        modelVersion: String,
        taxonomyVersion: String,
        trainedAt: Date?,
        trainingDataRows: Int?,
        accuracy: Double?,
        macroF1: Double?,
        notes: String?
    ) {
        self.modelVersion = modelVersion
        self.taxonomyVersion = taxonomyVersion
        self.trainedAt = trainedAt
        self.trainingDataRows = trainingDataRows
        self.accuracy = accuracy
        self.macroF1 = macroF1
        self.notes = notes
    }

    public static let rulesBased = ModelMetadata(
        modelVersion: "rules-1.0.0",
        taxonomyVersion: CategoryTaxonomy.current.version,
        trainedAt: nil,
        trainingDataRows: nil,
        accuracy: nil,
        macroF1: nil,
        notes: "Deterministic rule-based fallback — no Core ML model loaded."
    )
}
