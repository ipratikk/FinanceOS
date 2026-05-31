import Foundation

/// Structured context assembled by the intelligence pipeline for description generation.
/// Both `FallbackGenerator` (deterministic) and `AppleIntelligenceAdapter` (AI) consume this.
public struct DescriptionContext: Sendable {
    /// Canonical merchant name (e.g. "Spotify", "Max Life Insurance").
    public let merchantName: String
    /// Classified intent (e.g. `.salary`, `.subscription`).
    public let intent: TransactionIntent
    /// Relationship context — non-nil for P2P transfers with a known person.
    public let relationship: RelationshipType?
    /// Recurring pattern context — non-nil when this transaction is part of a pattern.
    public let recurringCadence: RecurringCadence?
    /// True when this transaction belongs to a confirmed recurring pattern.
    public let isRecurring: Bool
    /// Category for fallback when intent is `.unknown`.
    public let categoryId: String?
    /// True when the amount was large relative to account norms.
    public let isLargeAmount: Bool
    /// True when this is a debit (payment) vs credit (receipt).
    public let isDebit: Bool

    public init(
        merchantName: String,
        intent: TransactionIntent,
        relationship: RelationshipType? = nil,
        recurringCadence: RecurringCadence? = nil,
        isRecurring: Bool = false,
        categoryId: String? = nil,
        isLargeAmount: Bool = false,
        isDebit: Bool = true
    ) {
        self.merchantName = merchantName
        self.intent = intent
        self.relationship = relationship
        self.recurringCadence = recurringCadence
        self.isRecurring = isRecurring
        self.categoryId = categoryId
        self.isLargeAmount = isLargeAmount
        self.isDebit = isDebit
    }
}
