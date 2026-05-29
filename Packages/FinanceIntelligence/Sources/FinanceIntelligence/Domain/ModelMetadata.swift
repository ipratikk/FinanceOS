import Foundation

/// Descriptive metadata for a categorization model, stored alongside predictions for auditability.
/// Optional fields are nil for deterministic rule sets that have no training metrics.
public struct ModelMetadata: Codable, Sendable {
    /// Semantic version of the model or rule set (e.g. `"rules-1.0.0"`, `"text-classifier-v1"`).
    public let modelVersion: String
    /// Taxonomy version the model was trained or validated against.
    public let taxonomyVersion: String
    /// When the model was trained. Nil for rule-based categorizers.
    public let trainedAt: Date?
    /// Number of labeled examples used during training. Nil for rule-based categorizers.
    public let trainingDataRows: Int?
    /// Overall accuracy on the held-out test set, in [0, 1]. Nil for rule-based categorizers.
    public let accuracy: Double?
    /// Macro-averaged F1 across all categories, in [0, 1]. Nil for rule-based categorizers.
    public let macroF1: Double?
    /// Free-text notes (training dataset source, known weaknesses, etc.).
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

    /// Sentinel metadata for the deterministic rule-based categorizer (no ML model loaded).
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
