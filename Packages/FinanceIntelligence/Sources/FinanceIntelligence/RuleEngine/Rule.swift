import Foundation

/// A boolean feature indicator extracted from a transaction's description.
/// Maps directly to the boolean fields on `TransactionFeatures`.
public enum TransactionIndicator: String, Sendable, CaseIterable {
    case payroll // features.hasPayrollIndicator
    case refund // features.hasRefundIndicator
    case transfer // features.hasTransferIndicator
    case recurring // features.hasRecurringIndicator
    case online // features.hasOnlineIndicator
}

/// A condition that can be evaluated against `TransactionFeatures`.
public indirect enum RuleCondition: Sendable {
    /// At least one of the keywords appears in `normalizedDescription`.
    case tokenContainsAny([String])
    /// All keywords appear in `normalizedDescription`.
    case tokenContainsAll([String])
    /// The transaction has the specified boolean indicator.
    case hasIndicator(TransactionIndicator)
    /// The transaction is a credit (money coming in).
    case isCredit
    /// The transaction is a debit (money going out).
    case isDebit
    /// All sub-conditions must be true (AND).
    case compound([RuleCondition])
    /// At least one sub-condition must be true (OR).
    case anyOf([RuleCondition])
}

/// The classification outcome when a `Rule` matches.
public struct RuleOutcome: Sendable {
    /// Top-level category ID from `CategoryTaxonomy`. Nil when the rule only sets intent.
    public let categoryId: String?
    /// Subcategory ID (e.g. `"income.salary"`). Nil when no subcategory applies.
    public let subcategoryId: String?
    /// Intent classification for the transaction.
    public let intent: TransactionIntent
    /// Confidence in [0, 1].
    public let confidence: Double

    public init(
        categoryId: String?,
        subcategoryId: String? = nil,
        intent: TransactionIntent,
        confidence: Double
    ) {
        self.categoryId = categoryId
        self.subcategoryId = subcategoryId
        self.intent = intent
        self.confidence = confidence
    }
}

/// A single classification rule evaluated by `RuleEngine`.
public struct Rule: Sendable {
    /// Unique identifier (used in result provenance and tests).
    public let id: String
    /// Evaluation order — lower priority is evaluated first. First match wins.
    public let priority: Int
    /// Boolean condition evaluated against `TransactionFeatures`.
    public let condition: RuleCondition
    /// Classification produced when `condition` is true.
    public let outcome: RuleOutcome

    public init(id: String, priority: Int, condition: RuleCondition, outcome: RuleOutcome) {
        self.id = id
        self.priority = priority
        self.condition = condition
        self.outcome = outcome
    }
}

/// The result produced by `RuleEngine.evaluate()`.
public struct RuleEngineResult: Sendable {
    /// Category prediction from the matched rule, or nil if no rule produced a category.
    public let categoryPrediction: CategoryPrediction?
    /// Intent prediction — always present (`.unknown` when no rule matched).
    public let intentPrediction: IntentPrediction
    /// ID of the rule that matched, or nil for fallback.
    public let matchedRuleId: String?

    public init(
        categoryPrediction: CategoryPrediction?,
        intentPrediction: IntentPrediction,
        matchedRuleId: String?
    ) {
        self.categoryPrediction = categoryPrediction
        self.intentPrediction = intentPrediction
        self.matchedRuleId = matchedRuleId
    }
}
