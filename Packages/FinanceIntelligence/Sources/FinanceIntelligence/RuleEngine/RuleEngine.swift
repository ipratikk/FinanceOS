import Foundation

/// Evaluates an ordered list of `Rule`s against `TransactionFeatures` and returns the first match.
///
/// Rules are evaluated in ascending priority order (lowest integer = highest priority).
/// The first rule whose condition is satisfied wins; remaining rules are skipped.
///
/// The engine always returns an `IntentPrediction` (`.unknown` when nothing matches).
/// `categoryPrediction` in the result is nil only when the matched rule specifies no category.
public struct RuleEngine: Sendable {
    private let rules: [Rule]
    private let taxonomy: CategoryTaxonomy

    public init(rules: [Rule] = BuiltInRules.all, taxonomy: CategoryTaxonomy = .current) {
        self.rules = rules.sorted { $0.priority < $1.priority }
        self.taxonomy = taxonomy
    }

    /// Evaluates `features` against all rules and returns the best match.
    public func evaluate(_ features: TransactionFeatures) -> RuleEngineResult {
        for rule in rules {
            guard matches(rule.condition, against: features) else { continue }
            return buildResult(from: rule, features: features)
        }
        return RuleEngineResult(
            categoryPrediction: nil,
            intentPrediction: .unknown,
            matchedRuleId: nil
        )
    }
}

// MARK: - Condition Evaluation

private extension RuleEngine {
    func matches(_ condition: RuleCondition, against features: TransactionFeatures) -> Bool {
        switch condition {
        case .tokenContainsAny(let keywords):
            return keywords.contains { features.normalizedDescription.contains($0) }

        case .tokenContainsAll(let keywords):
            return keywords.allSatisfy { features.normalizedDescription.contains($0) }

        case .hasIndicator(let indicator):
            return indicatorValue(indicator, features: features)

        case .isCredit:
            return !features.isDebit

        case .isDebit:
            return features.isDebit

        case .compound(let conditions):
            return conditions.allSatisfy { matches($0, against: features) }

        case .anyOf(let conditions):
            return conditions.contains { matches($0, against: features) }
        }
    }

    func indicatorValue(_ indicator: TransactionIndicator, features: TransactionFeatures) -> Bool {
        switch indicator {
        case .payroll:   return features.hasPayrollIndicator
        case .refund:    return features.hasRefundIndicator
        case .transfer:  return features.hasTransferIndicator
        case .recurring: return features.hasRecurringIndicator
        case .online:    return features.hasOnlineIndicator
        }
    }
}

// MARK: - Result Construction

private extension RuleEngine {
    func buildResult(from rule: Rule, features: TransactionFeatures) -> RuleEngineResult {
        let intentPrediction = IntentPrediction(
            intent: rule.outcome.intent,
            confidence: rule.outcome.confidence,
            source: .ruleEngine
        )

        guard let categoryId = rule.outcome.categoryId else {
            return RuleEngineResult(
                categoryPrediction: nil,
                intentPrediction: intentPrediction,
                matchedRuleId: rule.id
            )
        }

        let displayName = taxonomy.category(forId: categoryId)?.displayName ?? categoryId
        let categoryPrediction = CategoryPrediction(
            categoryId: categoryId,
            subcategoryId: rule.outcome.subcategoryId,
            displayName: displayName,
            confidence: rule.outcome.confidence,
            alternatives: [],
            source: .rules,
            modelVersion: ModelMetadata.rulesBased.modelVersion,
            taxonomyVersion: taxonomy.version
        )

        return RuleEngineResult(
            categoryPrediction: categoryPrediction,
            intentPrediction: intentPrediction,
            matchedRuleId: rule.id
        )
    }
}
