import Foundation

// MARK: - ReasonCode

/// A structured explanation code attached to a prediction.
public struct ReasonCode: Codable, Equatable, Sendable {
    public let code: String
    public let message: String
    public let strength: Double?
    public let source: String

    public init(code: String, message: String, strength: Double? = nil, source: String) {
        self.code = code
        self.message = message
        self.strength = strength
        self.source = source
    }
}

// MARK: - CategoryAlternative

/// A runner-up category prediction returned alongside the top prediction.
public struct CategoryAlternative: Sendable, Codable {
    public let categoryId: String
    public let confidence: Double

    public init(categoryId: String, confidence: Double) {
        self.categoryId = categoryId
        self.confidence = confidence
    }
}

// MARK: - CategoryPrediction

/// The output of the categorization pipeline for a single transaction.
/// `confidence` is in [0, 1]; values below 0.5 indicate low-confidence predictions.
public struct CategoryPrediction: Sendable, Codable {
    public let categoryId: String
    public let subcategoryId: String?
    public let displayName: String
    public let confidence: Double
    public let alternatives: [CategoryAlternative]
    public let source: IntelligenceSource
    public let modelVersion: String
    public let taxonomyVersion: String

    // MARK: Provenance fields (INTEL-003)

    /// Intent subcategory from the rule that fired, e.g. `"salary"`, `"emi"`.
    public let intentId: String?
    /// How to interpret `confidence`. Use `.deterministic` for hard rules, `.uncalibratedScore` for kNN.
    public let confidenceKind: ConfidenceKind
    /// Stable ID of the rule that produced this prediction. Nil for ML paths.
    public let ruleId: String?
    /// Config version active when the prediction was made.
    public let configVersion: String?
    /// Machine-readable explanation codes for why this prediction was made.
    public let reasonCodes: [ReasonCode]

    public init(
        categoryId: String,
        subcategoryId: String?,
        displayName: String,
        confidence: Double,
        alternatives: [CategoryAlternative],
        source: IntelligenceSource,
        modelVersion: String,
        taxonomyVersion: String,
        intentId: String? = nil,
        confidenceKind: ConfidenceKind = .uncalibratedScore,
        ruleId: String? = nil,
        configVersion: String? = nil,
        reasonCodes: [ReasonCode] = []
    ) {
        self.categoryId = categoryId
        self.subcategoryId = subcategoryId
        self.displayName = displayName
        self.confidence = confidence
        self.alternatives = alternatives
        self.source = source
        self.modelVersion = modelVersion
        self.taxonomyVersion = taxonomyVersion
        self.intentId = intentId
        self.confidenceKind = confidenceKind
        self.ruleId = ruleId
        self.configVersion = configVersion
        self.reasonCodes = reasonCodes
    }

    /// Low-confidence fallback prediction for transactions that could not be categorized.
    public static func uncategorized(modelVersion: String, taxonomyVersion: String) -> CategoryPrediction {
        CategoryPrediction(
            categoryId: "uncategorized",
            subcategoryId: nil,
            displayName: "Uncategorized",
            confidence: 0.3,
            alternatives: [],
            source: .fallbackRule,
            modelVersion: modelVersion,
            taxonomyVersion: taxonomyVersion,
            confidenceKind: .notApplicable
        )
    }
}
