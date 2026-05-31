import Foundation

/// Classifies a person's relationship to the user based on behavioral signals.
public struct RelationshipClassifier: Sendable {
    public init() {}

    public struct Input: Sendable {
        public let personId: String
        public let personName: String
        public let totalDebits: Int64
        public let totalCredits: Int64
        public let transactionCount: Int
        public let averageDebitAmount: Int64
        public let signals: [RelationshipSignal]
        public let pattern: RecurringPattern?
        /// Dominant intent across transactions — used to exclude credit card payments from landlord heuristic.
        public let dominantIntentId: String?

        public init(
            personId: String, personName: String,
            totalDebits: Int64, totalCredits: Int64,
            transactionCount: Int, averageDebitAmount: Int64,
            signals: [RelationshipSignal], pattern: RecurringPattern? = nil,
            dominantIntentId: String? = nil
        ) {
            self.personId = personId
            self.personName = personName
            self.totalDebits = totalDebits
            self.totalCredits = totalCredits
            self.transactionCount = transactionCount
            self.averageDebitAmount = averageDebitAmount
            self.signals = signals
            self.pattern = pattern
            self.dominantIntentId = dominantIntentId
        }
    }

    public func classify(_ input: Input) -> (type: RelationshipType, confidence: Double) {
        // Credit card payments and generic transfers are never landlord
        let excludeFromLandlord = ["credit_card_payment", "transfer", "unknown"]
        let dominantIntent = input.dominantIntentId ?? input.pattern?.intentId ?? ""
        let isExcluded = excludeFromLandlord.contains(dominantIntent)
        if !isExcluded, isLikelyLandlord(input) { return (.landlord, landlordConfidence(input)) }
        if input.totalCredits > input.totalDebits * 3, input.transactionCount >= 3 {
            return (.employer, 0.65)
        }
        if input.signals.contains(.recurringAmount), input.averageDebitAmount > 500_000 {
            return (.family, 0.55)
        }
        if input.totalCredits > 0, input.transactionCount <= 5 { return (.reimbursement, 0.50) }
        if input.transactionCount >= 2, input.averageDebitAmount < 500_000 { return (.friend, 0.45) }
        return (.unknown, 0.30)
    }

    // MARK: - Private

    private func isLikelyLandlord(_ input: Input) -> Bool {
        input.pattern?.cadence == .monthly &&
            (input.signals.contains(.roundNumber) ||
                input.signals.contains(.postSalaryTiming) ||
                input.signals.contains(.upiLabel))
    }

    private func landlordConfidence(_ input: Input) -> Double {
        var conf = 0.55
        if input.pattern?.cadence == .monthly { conf += 0.10 }
        if input.signals.contains(.roundNumber) { conf += 0.08 }
        if input.signals.contains(.postSalaryTiming) { conf += 0.10 }
        if input.signals.contains(.upiLabel) { conf += 0.07 }
        if let count = input.pattern?.occurrenceCount, count >= 3 { conf += 0.05 }
        return min(conf, 0.95)
    }
}
