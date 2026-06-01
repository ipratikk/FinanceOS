import Foundation

/// Infers person-level relationships from transaction behavioral patterns.
public struct RelationshipEngine: Sendable {
    private let classifier: RelationshipClassifier
    private let config: RelationshipConfig
    private static let rentKeywords = ["rent", "owner", "landlord", "sir", "maam", "aunty", "uncle"]

    public init(config: RelationshipConfig = IntelligenceConfig.defaultV1.relationship) {
        self.config = config
        classifier = RelationshipClassifier()
    }

    public struct TransactionRecord: Sendable {
        public let amount: Int64
        public let isDebit: Bool
        public let postedAt: Date
        public let rawDescription: String
        public let pattern: RecurringPattern?

        public init(
            amount: Int64, isDebit: Bool, postedAt: Date,
            rawDescription: String, pattern: RecurringPattern? = nil
        ) {
            self.amount = amount
            self.isDebit = isDebit
            self.postedAt = postedAt
            self.rawDescription = rawDescription
            self.pattern = pattern
        }
    }

    public func inferRelationship(
        personId: String, personName: String,
        transactions: [TransactionRecord],
        salaryCreditDates: [Date] = []
    ) -> Relationship? {
        guard !transactions.isEmpty else { return nil }
        let debits = transactions.filter(\.isDebit)
        let credits = transactions.filter { !$0.isDebit }
        let totalDebits = debits.map(\.amount).reduce(0, +)
        let totalCredits = credits.map(\.amount).reduce(0, +)
        let avgDebit = debits.isEmpty ? 0 : totalDebits / Int64(debits.count)
        let pattern = transactions.compactMap(\.pattern).first
        let signals = buildSignals(debits: debits, salaryCreditDates: salaryCreditDates, pattern: pattern)

        let dominantIntentId = pattern?.intentId
        let input = RelationshipClassifier.Input(
            personId: personId, personName: personName,
            totalDebits: totalDebits, totalCredits: totalCredits,
            transactionCount: transactions.count, averageDebitAmount: avgDebit,
            signals: signals, pattern: pattern,
            dominantIntentId: dominantIntentId
        )
        let (type, confidence) = classifier.classify(input)
        guard confidence >= config.minConfidence else { return nil }
        return Relationship(
            toPersonId: personId, type: type, confidence: confidence,
            evidenceCount: transactions.count, signals: signals
        )
    }

    public func inferRelationshipWithDebug(
        personId: String, personName: String,
        transactions: [TransactionRecord],
        salaryCreditDates: [Date] = []
    ) -> (Relationship, RelationshipDebugInfo)? {
        guard let relationship = inferRelationship(
            personId: personId, personName: personName,
            transactions: transactions, salaryCreditDates: salaryCreditDates
        ) else { return nil }

        let debits = transactions.filter(\.isDebit)
        let pattern = transactions.compactMap(\.pattern).first
        let signals = relationship.signals
        let evidence = buildEvidence(
            signals: signals, debits: debits,
            salaryCreditDates: salaryCreditDates, pattern: pattern
        )
        let debugInfo = RelationshipDebugInfo(
            personId: personId, candidateType: relationship.type,
            confidence: relationship.confidence, confidenceKind: .heuristicOrdinal,
            evidence: evidence, excludedByRules: [], configVersion: "defaultV1"
        )
        return (relationship, debugInfo)
    }

    // MARK: - Private

    private func buildEvidence(
        signals: [RelationshipSignal],
        debits: [TransactionRecord],
        salaryCreditDates: [Date],
        pattern: RecurringPattern?
    ) -> [RelationshipEvidence] {
        var evidence: [RelationshipEvidence] = []
        if signals.contains(.recurringAmount) {
            evidence.append(RelationshipEvidence(code: "monthly_cadence_detected", value: "true"))
        }
        if signals.contains(.postSalaryTiming) {
            evidence.append(RelationshipEvidence(code: "post_salary_payment_detected", value: "true"))
        }
        if signals.contains(.roundNumber) {
            evidence.append(RelationshipEvidence(code: "round_amount_detected", value: "true"))
        }
        if signals.contains(.upiLabel) {
            evidence.append(RelationshipEvidence(code: "rent_keyword_detected", value: "true"))
        }
        if signals.contains(.regularInterval) {
            evidence.append(RelationshipEvidence(code: "regular_interval_detected", value: "true"))
        }
        let debitRatio = debits.isEmpty ? 0.0 : Double(debits.count) / Double(debits.count + (debits.isEmpty ? 1 : 0))
        evidence.append(RelationshipEvidence(
            code: "debit_transaction_ratio",
            value: String(format: "%.2f", debitRatio)
        ))
        if let occCount = pattern?.occurrenceCount {
            evidence.append(RelationshipEvidence(code: "occurrence_count", value: "\(occCount)"))
        }
        return evidence
    }

    private func buildSignals(
        debits: [TransactionRecord], salaryCreditDates: [Date], pattern: RecurringPattern?
    ) -> [RelationshipSignal] {
        var signals: [RelationshipSignal] = []
        if let p = pattern, p.cadence == .monthly { signals.append(.recurringAmount) }
        if isRoundAmount(debits: debits) { signals.append(.roundNumber) }
        if hasRegularInterval(debits: debits) { signals.append(.regularInterval) }
        if hasPostSalaryTiming(debits: debits, salaryCreditDates: salaryCreditDates) {
            signals.append(.postSalaryTiming)
        }
        if containsRentKeywords(debits: debits) { signals.append(.upiLabel) }
        return signals
    }

    private func isRoundAmount(debits: [TransactionRecord]) -> Bool {
        guard !debits.isEmpty else { return false }
        return Double(debits.count(where: {
            $0.amount % config.roundAmountGranularityMinorUnits == 0
        })) / Double(debits.count) >= 0.7
    }

    private func hasRegularInterval(debits: [TransactionRecord]) -> Bool {
        guard debits.count >= 2 else { return false }
        let intervals = zip(
            debits.map(\.postedAt).sorted().dropFirst(),
            debits.map(\.postedAt).sorted()
        ).map { $0.timeIntervalSince($1) / 86400 }
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intervals.count)
        return sqrt(variance) < mean * 0.25
    }

    private func hasPostSalaryTiming(debits: [TransactionRecord], salaryCreditDates: [Date]) -> Bool {
        guard !salaryCreditDates.isEmpty else { return false }
        let postCount = debits.count(where: { debit in
            salaryCreditDates.contains { salary in
                let diff = debit.postedAt.timeIntervalSince(salary) / 86400
                return diff >= 0 && diff <= Double(config.postSalaryWindowDays)
            }
        })
        return Double(postCount) / Double(debits.count) >= 0.5
    }

    private func containsRentKeywords(debits: [TransactionRecord]) -> Bool {
        debits.contains { txn in
            let lower = txn.rawDescription.lowercased()
            return Self.rentKeywords.contains { lower.contains($0) }
        }
    }
}
