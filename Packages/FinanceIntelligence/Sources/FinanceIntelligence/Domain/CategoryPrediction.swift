import Foundation

public enum PredictionSource: String, Codable, Sendable {
    case rules
    case alias
    case mlModel
    case userCorrection
    case fallback
}

public struct CategoryAlternative: Sendable, Codable {
    public let categoryId: String
    public let confidence: Double

    public init(categoryId: String, confidence: Double) {
        self.categoryId = categoryId
        self.confidence = confidence
    }
}

public struct CategoryPrediction: Sendable, Codable {
    public let categoryId: String
    public let subcategoryId: String?
    public let displayName: String
    public let confidence: Double
    public let alternatives: [CategoryAlternative]
    public let source: PredictionSource
    public let modelVersion: String
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
