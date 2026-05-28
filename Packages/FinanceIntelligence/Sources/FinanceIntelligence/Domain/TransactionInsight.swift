import Foundation

public enum InsightKind: String, Codable, Sendable {
    case recurringTransaction
    case subscriptionDetected
    case spendingSpike
    case categoryTrend
    case merchantTrend
    case unusuallyLargeTransaction
}

public enum InsightSeverity: String, Codable, Sendable {
    case info
    case warning
    case alert
}

public struct TransactionInsight: Identifiable, Sendable, Codable {
    public let id: UUID
    public let kind: InsightKind
    public let title: String
    public let explanation: String
    public let affectedTransactionIDs: [String]
    public let confidence: Double
    public let severity: InsightSeverity
    public let generatedAt: Date

    public init(
        kind: InsightKind,
        title: String,
        explanation: String,
        affectedTransactionIDs: [String],
        confidence: Double,
        severity: InsightSeverity
    ) {
        id = UUID()
        self.kind = kind
        self.title = title
        self.explanation = explanation
        self.affectedTransactionIDs = affectedTransactionIDs
        self.confidence = confidence
        self.severity = severity
        generatedAt = Date()
    }
}
