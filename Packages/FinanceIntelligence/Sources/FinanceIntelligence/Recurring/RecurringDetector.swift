import Foundation

/// Detects recurring payment patterns from a corpus of transactions.
public struct RecurringDetector: Sendable {
    private let analyzer: PatternAnalyzer
    private let schedule: ScheduleInference
    private let config: RecurringConfig

    public init(config: RecurringConfig = IntelligenceConfig.defaultV1.recurring) {
        self.config = config
        analyzer = PatternAnalyzer()
        schedule = ScheduleInference()
    }

    public struct DetectionInput: Sendable {
        public let transactionId: UUID
        public let merchantKey: String
        public let personId: String?
        public let amountMinorUnits: Int64
        public let postedAt: Date
        public let categoryId: String
        public let intentId: String

        public init(
            transactionId: UUID,
            merchantKey: String,
            personId: String? = nil,
            amountMinorUnits: Int64,
            postedAt: Date,
            categoryId: String,
            intentId: String
        ) {
            self.transactionId = transactionId
            self.merchantKey = merchantKey
            self.personId = personId
            self.amountMinorUnits = amountMinorUnits
            self.postedAt = postedAt
            self.categoryId = categoryId
            self.intentId = intentId
        }
    }

    public func detect(from transactions: [DetectionInput]) -> [RecurringPattern] {
        Dictionary(grouping: transactions) { $0.merchantKey }
            .compactMap { key, group in
                guard group.count >= config.minOccurrencesDefault else { return nil }
                return detectPattern(merchantKey: key, group: group)
            }
            .filter { pattern in
                pattern.occurrenceCount >= config.minOccurrences(for: pattern.cadence)
            }
            .sorted { $0.confidence > $1.confidence }
    }

    public func detectWithDebugInfo(
        from transactions: [DetectionInput]
    ) -> [(pattern: RecurringPattern, debug: RecurringPatternDebugInfo)] {
        Dictionary(grouping: transactions) { $0.merchantKey }
            .compactMap { key, group -> (RecurringPattern, RecurringPatternDebugInfo)? in
                guard group.count >= config.minOccurrencesDefault else { return nil }
                return detectPatternWithDebug(merchantKey: key, group: group)
            }
            .sorted { $0.0.confidence > $1.0.confidence }
    }

    // MARK: - Private

    private func detectPattern(merchantKey: String, group: [DetectionInput]) -> RecurringPattern? {
        let dates = group.map(\.postedAt).sorted()
        guard let (cadence, confidence) = analyzer.analyzeCadence(
            dates: dates,
            toleranceDays: { config.toleranceDays(for: $0) }
        ), cadence != .irregular || confidence >= 0.5 else { return nil }

        let amounts = group.map(\.amountMinorUnits)
        let avg = amounts.reduce(0, +) / Int64(amounts.count)
        let variance = avg > 0
            ? amounts.map { Double(abs($0 - avg)) / Double(avg) }.reduce(0, +) / Double(amounts.count)
            : 0.0
        let dayHint = cadence == .monthly ? analyzer.dayOfMonthHint(from: dates) : nil
        let mostCommon = group.max { a, b in
            group.count(where: { $0.categoryId == a.categoryId }) <
                group.count(where: { $0.categoryId == b.categoryId })
        }

        return RecurringPattern(
            merchantKey: merchantKey,
            personId: group.first?.personId,
            categoryId: mostCommon?.categoryId ?? "transfers",
            intentId: mostCommon?.intentId ?? "unknown",
            cadence: cadence,
            averageAmountMinorUnits: avg,
            amountVariancePercent: variance,
            dayOfMonthHint: dayHint,
            confidence: confidence,
            occurrenceCount: group.count,
            lastSeenAt: dates.last ?? Date()
        )
    }

    private func detectPatternWithDebug(
        merchantKey: String,
        group: [DetectionInput]
    ) -> (RecurringPattern, RecurringPatternDebugInfo)? {
        let dates = group.map(\.postedAt).sorted()
        let intervalInts = analyzer.intervals(from: dates)
        guard let (cadence, confidence) = analyzer.analyzeCadence(
            dates: dates,
            toleranceDays: { config.toleranceDays(for: $0) }
        ), cadence != .irregular || confidence >= 0.5 else { return nil }

        let toleranceDaysInt = Int(config.toleranceDays(for: cadence))
        let minOcc = config.minOccurrences(for: cadence)
        let isLowEvidence = group.count < minOcc
        let amounts = group.map(\.amountMinorUnits)
        let avg = amounts.reduce(0, +) / Int64(amounts.count)
        let cv: Double? = avg > 0
            ? amounts.map { Double(abs($0 - avg)) / Double(avg) }.reduce(0, +) / Double(amounts.count)
            : nil

        let debugInfo = RecurringPatternDebugInfo(
            merchantKey: merchantKey,
            observedIntervals: intervalInts,
            candidateCadence: cadence,
            toleranceDays: toleranceDaysInt,
            occurrenceCount: group.count,
            amountCoefficientOfVariation: cv,
            confidence: confidence,
            confidenceKind: .heuristicOrdinal,
            isLowEvidence: isLowEvidence,
            configVersion: "defaultV1"
        )

        guard let pattern = detectPattern(merchantKey: merchantKey, group: group) else { return nil }
        return (pattern, debugInfo)
    }
}
