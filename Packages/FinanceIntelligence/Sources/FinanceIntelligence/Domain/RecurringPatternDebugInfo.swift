import Foundation

public struct RecurringPatternDebugInfo: Codable, Equatable, Sendable {
    public let merchantKey: String
    public let observedIntervals: [Int]
    public let candidateCadence: RecurringCadence
    public let toleranceDays: Int
    public let occurrenceCount: Int
    public let amountCoefficientOfVariation: Double?
    public let confidence: Double
    public let confidenceKind: ConfidenceKind
    public let isLowEvidence: Bool
    public let configVersion: String

    public init(
        merchantKey: String,
        observedIntervals: [Int],
        candidateCadence: RecurringCadence,
        toleranceDays: Int,
        occurrenceCount: Int,
        amountCoefficientOfVariation: Double?,
        confidence: Double,
        confidenceKind: ConfidenceKind,
        isLowEvidence: Bool,
        configVersion: String
    ) {
        self.merchantKey = merchantKey
        self.observedIntervals = observedIntervals
        self.candidateCadence = candidateCadence
        self.toleranceDays = toleranceDays
        self.occurrenceCount = occurrenceCount
        self.amountCoefficientOfVariation = amountCoefficientOfVariation
        self.confidence = confidence
        self.confidenceKind = confidenceKind
        self.isLowEvidence = isLowEvidence
        self.configVersion = configVersion
    }
}
