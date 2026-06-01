import Foundation

/// Classifies the type of pattern detected by `SpendingInsightEngine`.
public enum InsightKind: String, Codable, Sendable {
    /// A charge that appears on a non-monthly recurring schedule.
    case recurringTransaction
    /// A charge that appears monthly with a consistent amount, likely a subscription.
    case subscriptionDetected
    /// Monthly spending is more than two standard deviations above recent history.
    case spendingSpike
    /// A category's share of spending has shifted significantly over time.
    case categoryTrend
    /// Spend at a specific merchant has changed significantly.
    case merchantTrend
    /// A single debit is more than three standard deviations above the mean debit amount.
    case unusuallyLargeTransaction
}

/// Indicates the urgency level for displaying a `TransactionInsight` to the user.
public enum InsightSeverity: String, Codable, Sendable {
    /// Informational — no action required.
    case info
    /// Worth reviewing — potential unexpected charge or trend.
    case warning
    /// Requires attention — anomalous transaction or significant overspend.
    case alert
}

/// Statistical backing for a spike or anomaly insight.
public struct InsightEvidence: Codable, Equatable, Sendable {
    public let baselineMean: Double
    public let baselineStdDev: Double
    public let observedValue: Double
    public let absoluteDelta: Double
    public let relativeDelta: Double
    public let thresholdUsed: Double

    public init(
        baselineMean: Double,
        baselineStdDev: Double,
        observedValue: Double,
        absoluteDelta: Double,
        relativeDelta: Double,
        thresholdUsed: Double
    ) {
        self.baselineMean = baselineMean
        self.baselineStdDev = baselineStdDev
        self.observedValue = observedValue
        self.absoluteDelta = absoluteDelta
        self.relativeDelta = relativeDelta
        self.thresholdUsed = thresholdUsed
    }
}

/// A single insight surfaced by `SpendingInsightEngine` over a set of analyzed transactions.
/// `confidence` is in [0, 1] and reflects the statistical strength of the detected pattern.
public struct TransactionInsight: Identifiable, Sendable, Codable {
    /// Stable identifier for this insight instance.
    public let id: UUID
    /// The pattern type detected.
    public let kind: InsightKind
    /// Short display title for the insight card.
    public let title: String
    /// One-sentence human-readable explanation of the detected pattern.
    public let explanation: String
    /// Transaction IDs (UUID strings) that contributed to this insight.
    public let affectedTransactionIDs: [String]
    /// Statistical confidence for this insight, in [0, 1].
    public let confidence: Double
    /// Urgency level for UI presentation.
    public let severity: InsightSeverity
    /// Timestamp when the insight was computed.
    public let generatedAt: Date
    /// Statistical backing for spike/anomaly insights; nil for non-quantitative insights.
    public let evidence: InsightEvidence?

    public init(
        kind: InsightKind,
        title: String,
        explanation: String,
        affectedTransactionIDs: [String],
        confidence: Double,
        severity: InsightSeverity,
        evidence: InsightEvidence? = nil
    ) {
        id = UUID()
        self.kind = kind
        self.title = title
        self.explanation = explanation
        self.affectedTransactionIDs = affectedTransactionIDs
        self.confidence = confidence
        self.severity = severity
        generatedAt = Date()
        self.evidence = evidence
    }
}
