import Foundation

/// Identifies which component of the intelligence pipeline produced a category prediction.
public enum PredictionSource: String, Codable, Sendable {
    /// Matched by the deterministic keyword-rule engine.
    case rules
    /// Matched by the merchant alias table lookup.
    case alias
    /// Produced by the bundled CoreML text classifier or on-device kNN model.
    case mlModel
    /// Overridden by an explicit user correction — highest priority source.
    case userCorrection
    /// No signal was available; the "Uncategorized" category was assigned.
    case fallback
}

/// A runner-up category prediction returned alongside the top prediction.
public struct CategoryAlternative: Sendable, Codable {
    /// Taxonomy category ID of the alternative.
    public let categoryId: String
    /// Model confidence for this alternative, in [0, 1].
    public let confidence: Double

    public init(categoryId: String, confidence: Double) {
        self.categoryId = categoryId
        self.confidence = confidence
    }
}

/// The output of the categorization pipeline for a single transaction.
/// `confidence` is in [0, 1]; values below 0.5 indicate low-confidence predictions.
public struct CategoryPrediction: Sendable, Codable {
    /// Top-level taxonomy category ID (e.g. `"dining"`, `"transportation"`).
    public let categoryId: String
    /// Optional subcategory ID (e.g. `"dining.delivery"`). Nil when the model predicts top-level only.
    public let subcategoryId: String?
    /// Human-readable display name from the taxonomy for `categoryId`.
    public let displayName: String
    /// Prediction confidence in [0, 1]. User corrections always produce 1.0.
    public let confidence: Double
    /// Up to four runner-up predictions ordered by descending confidence.
    public let alternatives: [CategoryAlternative]
    /// Pipeline component that produced this prediction.
    public let source: PredictionSource
    /// Version string of the model or rule set used.
    public let modelVersion: String
    /// Version of `CategoryTaxonomy` used when the prediction was made.
    public let taxonomyVersion: String

    public init(
        categoryId: String,
        subcategoryId: String?,
        displayName: String,
        confidence: Double,
        alternatives: [CategoryAlternative],
        source: PredictionSource,
        modelVersion: String,
        taxonomyVersion: String
    ) {
        self.categoryId = categoryId
        self.subcategoryId = subcategoryId
        self.displayName = displayName
        self.confidence = confidence
        self.alternatives = alternatives
        self.source = source
        self.modelVersion = modelVersion
        self.taxonomyVersion = taxonomyVersion
    }

    /// Returns a low-confidence fallback prediction for transactions that could not be categorized.
    public static func uncategorized(modelVersion: String, taxonomyVersion: String) -> CategoryPrediction {
        CategoryPrediction(
            categoryId: "uncategorized",
            subcategoryId: nil,
            displayName: "Uncategorized",
            confidence: 0.3,
            alternatives: [],
            source: .fallback,
            modelVersion: modelVersion,
            taxonomyVersion: taxonomyVersion
        )
    }
}
