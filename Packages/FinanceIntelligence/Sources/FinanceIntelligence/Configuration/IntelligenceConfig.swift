import Foundation

// MARK: - Sub-Configs

/// Thresholds for the categorization pipeline.
public struct ClassificationConfig: Codable, Equatable, Sendable {
    /// Minimum rule confidence required for a high-confidence structural rule to override kNN.
    public let ruleConfidenceThreshold: Double
    /// Minimum kNN model confidence required to use a prediction.
    public let knnConfidenceThreshold: Double
    /// Minimum NL model confidence required to use a prediction. Nil = no floor applied.
    public let nlModelConfidenceThreshold: Double?

    public init(
        ruleConfidenceThreshold: Double,
        knnConfidenceThreshold: Double,
        nlModelConfidenceThreshold: Double? = nil
    ) {
        self.ruleConfidenceThreshold = ruleConfidenceThreshold
        self.knnConfidenceThreshold = knnConfidenceThreshold
        self.nlModelConfidenceThreshold = nlModelConfidenceThreshold
    }
}

/// Thresholds for person relationship inference.
public struct RelationshipConfig: Codable, Equatable, Sendable {
    /// Minimum classifier confidence to emit a Relationship record.
    public let minConfidence: Double
    /// Window in days after a salary credit in which a debit counts as post-salary.
    public let postSalaryWindowDays: Int
    /// Amount granularity (minor units) for "round amount" signal detection.
    public let roundAmountGranularityMinorUnits: Int64
    /// Minimum distinct transactions before relationship inference runs for a person.
    public let minTransactionsForInference: Int

    public init(
        minConfidence: Double,
        postSalaryWindowDays: Int,
        roundAmountGranularityMinorUnits: Int64,
        minTransactionsForInference: Int
    ) {
        self.minConfidence = minConfidence
        self.postSalaryWindowDays = postSalaryWindowDays
        self.roundAmountGranularityMinorUnits = roundAmountGranularityMinorUnits
        self.minTransactionsForInference = minTransactionsForInference
    }
}

/// Thresholds for recurring pattern detection.
public struct RecurringConfig: Codable, Equatable, Sendable {
    /// Minimum occurrences required before a merchant is considered recurring.
    public let minOccurrencesDefault: Int
    /// Coefficient of variation threshold for amount stability.
    public let amountCVThreshold: Double
    /// Per-cadence minimum occurrences; falls back to `minOccurrencesDefault` when key absent.
    public let minOccurrencesByCadence: [String: Int]
    /// Per-cadence tolerance in days; falls back to `RecurringCadence.toleranceDays` when key absent.
    public let toleranceDaysByCadence: [String: Int]

    public init(
        minOccurrencesDefault: Int,
        amountCVThreshold: Double,
        minOccurrencesByCadence: [String: Int] = [:],
        toleranceDaysByCadence: [String: Int] = [:]
    ) {
        self.minOccurrencesDefault = minOccurrencesDefault
        self.amountCVThreshold = amountCVThreshold
        self.minOccurrencesByCadence = minOccurrencesByCadence
        self.toleranceDaysByCadence = toleranceDaysByCadence
    }

    public func minOccurrences(for cadence: RecurringCadence) -> Int {
        minOccurrencesByCadence[cadence.rawValue] ?? minOccurrencesDefault
    }

    public func toleranceDays(for cadence: RecurringCadence) -> Double {
        toleranceDaysByCadence[cadence.rawValue].map { Double($0) } ?? cadence.toleranceDays
    }
}

/// Thresholds for spending insight detection.
public struct InsightConfig: Codable, Equatable, Sendable {
    /// Standard deviation multiplier for spending-spike detection.
    public let spikeStdDevMultiplier: Double
    /// Standard deviation multiplier for unusually-large transaction detection.
    public let anomalyStdDevMultiplier: Double
    /// Whether numeric confidence values may be shown in user-facing UI.
    public let exposeConfidenceToUser: Bool
    /// Absolute spend delta (minor units) below which spikes are suppressed regardless of stddev.
    public let absoluteSpikeThresholdMinorUnits: Int64

    public init(
        spikeStdDevMultiplier: Double,
        anomalyStdDevMultiplier: Double,
        exposeConfidenceToUser: Bool,
        absoluteSpikeThresholdMinorUnits: Int64 = 500_000
    ) {
        self.spikeStdDevMultiplier = spikeStdDevMultiplier
        self.anomalyStdDevMultiplier = anomalyStdDevMultiplier
        self.exposeConfidenceToUser = exposeConfidenceToUser
        self.absoluteSpikeThresholdMinorUnits = absoluteSpikeThresholdMinorUnits
    }
}

/// Thresholds for knowledge graph edge weight management.
public struct GraphConfig: Codable, Equatable, Sendable {
    /// Amount added to an edge's weight on each repeated observation.
    public let edgeWeightIncrement: Double
    /// Maximum edge weight (cap to prevent unbounded growth).
    public let edgeWeightMax: Double

    public init(edgeWeightIncrement: Double, edgeWeightMax: Double) {
        self.edgeWeightIncrement = edgeWeightIncrement
        self.edgeWeightMax = edgeWeightMax
    }
}

// MARK: - IntelligenceConfig

/// Top-level behavioral configuration for the intelligence pipeline.
/// Encodes all magic thresholds; default values match previously inline-hardcoded values.
public struct IntelligenceConfig: Codable, Equatable, Sendable {
    /// Opaque version string that flows into `CategoryPrediction.configVersion`.
    public let version: String
    public let classification: ClassificationConfig
    public let relationship: RelationshipConfig
    public let recurring: RecurringConfig
    public let insight: InsightConfig
    public let graph: GraphConfig

    public init(
        version: String,
        classification: ClassificationConfig,
        relationship: RelationshipConfig,
        recurring: RecurringConfig,
        insight: InsightConfig,
        graph: GraphConfig
    ) {
        self.version = version
        self.classification = classification
        self.relationship = relationship
        self.recurring = recurring
        self.insight = insight
        self.graph = graph
    }
}

// MARK: - Default

public extension IntelligenceConfig {
    /// Canonical production defaults. Values exactly match previously hardcoded inline values.
    static let defaultV1 = IntelligenceConfig(
        version: "2026-05-31.v1",
        classification: ClassificationConfig(
            ruleConfidenceThreshold: 0.92,
            knnConfidenceThreshold: 0.70
        ),
        relationship: RelationshipConfig(
            minConfidence: 0.40,
            postSalaryWindowDays: 7,
            roundAmountGranularityMinorUnits: 50000,
            minTransactionsForInference: 2
        ),
        recurring: RecurringConfig(
            minOccurrencesDefault: 2,
            amountCVThreshold: 0.15,
            minOccurrencesByCadence: ["weekly": 5, "monthly": 3, "quarterly": 3, "bi_weekly": 3, "yearly": 2],
            toleranceDaysByCadence: ["weekly": 2, "monthly": 5, "quarterly": 10, "bi_weekly": 3, "yearly": 20]
        ),
        insight: InsightConfig(
            spikeStdDevMultiplier: 2.0,
            anomalyStdDevMultiplier: 3.0,
            exposeConfidenceToUser: false,
            absoluteSpikeThresholdMinorUnits: 500_000
        ),
        graph: GraphConfig(
            edgeWeightIncrement: 0.1,
            edgeWeightMax: 10.0
        )
    )
}
