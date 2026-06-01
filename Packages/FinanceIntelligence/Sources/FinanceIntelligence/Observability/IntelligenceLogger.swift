import Foundation

// MARK: - Shared domain enums (also consumed by CategoryPrediction — INTEL-003)

/// Classifies how the confidence value should be interpreted.
public enum ConfidenceKind: String, Codable, Sendable, Equatable {
    case deterministic
    case calibratedProbability = "calibrated_probability"
    case uncalibratedScore = "uncalibrated_score"
    case heuristicOrdinal = "heuristic_ordinal"
    case notApplicable = "not_applicable"
}

/// Which component of the intelligence pipeline produced an output.
public enum IntelligenceSource: String, Codable, Sendable, Equatable {
    case userCorrection
    case structuralRule
    case personalizedKNN
    case coreMLNLModel
    case fallbackRule
    case manual
}

// MARK: - IntelligenceStage

/// Identifies the pipeline stage that produced an inference event.
public enum IntelligenceStage: String, Codable, Sendable {
    case narrationParsing, merchantNormalization, featureExtraction
    case ruleCategorization, personalizedKNN, nlModelCategorization, finalCategorization
    case personResolution, graphBuild, recurringDetection, relationshipInference
    case descriptionGeneration, spendingInsight
}

// MARK: - IntelligenceEvent

/// A structured record of a single intelligence pipeline decision.
/// PII rule: do NOT store raw narrations — use transactionId for linkage.
public struct IntelligenceEvent: Codable, Identifiable, Sendable {
    public let id: UUID
    public let transactionId: String?
    public let stage: IntelligenceStage
    public let source: IntelligenceSource
    public let ruleId: String?
    public let modelId: String?
    public let modelVersion: String?
    public let configVersion: String?
    public let outputLabel: String?
    public let outputIntent: String?
    public let confidence: Double?
    public let confidenceKind: ConfidenceKind
    public let debugJSON: String?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        transactionId: String? = nil,
        stage: IntelligenceStage,
        source: IntelligenceSource,
        ruleId: String? = nil,
        modelId: String? = nil,
        modelVersion: String? = nil,
        configVersion: String? = nil,
        outputLabel: String? = nil,
        outputIntent: String? = nil,
        confidence: Double? = nil,
        confidenceKind: ConfidenceKind,
        debugJSON: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.transactionId = transactionId
        self.stage = stage
        self.source = source
        self.ruleId = ruleId
        self.modelId = modelId
        self.modelVersion = modelVersion
        self.configVersion = configVersion
        self.outputLabel = outputLabel
        self.outputIntent = outputIntent
        self.confidence = confidence
        self.confidenceKind = confidenceKind
        self.debugJSON = debugJSON
        self.createdAt = createdAt
    }
}

// MARK: - IntelligenceLogger

/// Records structured inference events. Implementations must be `Sendable`.
public protocol IntelligenceLogger: Sendable {
    func record(_ event: IntelligenceEvent) async
}
