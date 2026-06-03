import FinanceCore
import Foundation

/// A fully enriched transaction output by the `IntelligencePipeline`.
/// Extends `AnalyzedTransaction` with intent, relationships, recurring context, and human description.
///
/// Fields marked "Phase N" are nil until that phase ships. Callers should handle nil gracefully.
public struct EnrichedTransaction: Sendable {
    /// Original transaction from the ledger.
    public let transaction: Transaction
    /// Canonical merchant resolved from the narration.
    public let merchantCandidate: MerchantCandidate
    /// Category assigned by the pipeline.
    public let categoryPrediction: CategoryPrediction
    /// Intent assigned by the RuleEngine (Phase 1+).
    public let intentPrediction: IntentPrediction
    /// Feature vector used during inference.
    public let features: TransactionFeatures
    /// True when category was set via a stored user correction.
    public let isUserCorrected: Bool
    /// Semver string identifying the pipeline version that produced this result.
    public let pipelineVersion: String

    // MARK: Future phases (nil in Phase 1)

    /// Resolved person and merchant entities. Populated in Phase 3.
    public let resolvedEntities: ResolvedEntities?
    /// Recurring pattern context. Populated in Phase 5.
    public let recurringContext: RecurringContext?
    /// Relationship to a person or institution. Populated in Phase 5.
    public let relationshipContext: RelationshipContext?
    /// Human-readable description. Populated in Phase 7.
    public let humanDescription: String?

    // MARK: FINOS-23 Model Predictions (stages 3-7)

    /// Income detection result. Populated in Stage 3 (FINOS-20).
    public let incomePrediction: IncomePrediction?
    /// Subscription detection result. Populated in Stage 6 (FINOS-22).
    public let subscriptionPrediction: SubscriptionPrediction?

    public init(
        transaction: Transaction,
        merchantCandidate: MerchantCandidate,
        categoryPrediction: CategoryPrediction,
        intentPrediction: IntentPrediction,
        features: TransactionFeatures,
        isUserCorrected: Bool,
        pipelineVersion: String = "1.0",
        resolvedEntities: ResolvedEntities? = nil,
        recurringContext: RecurringContext? = nil,
        relationshipContext: RelationshipContext? = nil,
        humanDescription: String? = nil,
        incomePrediction: IncomePrediction? = nil,
        subscriptionPrediction: SubscriptionPrediction? = nil
    ) {
        self.transaction = transaction
        self.merchantCandidate = merchantCandidate
        self.categoryPrediction = categoryPrediction
        self.intentPrediction = intentPrediction
        self.features = features
        self.isUserCorrected = isUserCorrected
        self.pipelineVersion = pipelineVersion
        self.resolvedEntities = resolvedEntities
        self.recurringContext = recurringContext
        self.relationshipContext = relationshipContext
        self.humanDescription = humanDescription
        self.incomePrediction = incomePrediction
        self.subscriptionPrediction = subscriptionPrediction
    }
}

// MARK: - FINOS-23 Model Prediction Types

/// Income detection result (Stage 3, IncomeClassifier v0.1).
public struct IncomePrediction: Sendable, Codable {
    public let isIncome: Bool
    public let confidence: Double

    public init(isIncome: Bool, confidence: Double) {
        self.isIncome = isIncome
        self.confidence = confidence
    }
}

/// Subscription detection result (Stage 6, HybridSubscriptionDetector).
public struct SubscriptionPrediction: Sendable, Codable {
    public let name: String
    public let confidence: Double

    public init(name: String, confidence: Double) {
        self.name = name
        self.confidence = confidence
    }
}

// MARK: - Phase 3+ Placeholder Types

/// Resolved merchant and person entities. Full implementation ships in Phase 3.
public struct ResolvedEntities: Sendable, Codable {
    public let merchantId: UUID?
    public let personId: UUID?

    public init(merchantId: UUID? = nil, personId: UUID? = nil) {
        self.merchantId = merchantId
        self.personId = personId
    }
}

/// Recurring pattern context attached to a transaction. Full implementation ships in Phase 5.
public struct RecurringContext: Sendable, Codable {
    public let patternId: UUID
    public let cadence: String
    public let confidence: Double
    public let expectedNextDate: Date?

    public init(patternId: UUID, cadence: String, confidence: Double, expectedNextDate: Date? = nil) {
        self.patternId = patternId
        self.cadence = cadence
        self.confidence = confidence
        self.expectedNextDate = expectedNextDate
    }
}

/// Relationship context attached to a transaction. Full implementation ships in Phase 5.
public struct RelationshipContext: Sendable, Codable {
    public let personId: UUID
    public let personName: String
    public let relationship: String
    public let confidence: Double

    public init(personId: UUID, personName: String, relationship: String, confidence: Double) {
        self.personId = personId
        self.personName = personName
        self.relationship = relationship
        self.confidence = confidence
    }
}
