import Foundation

/// A single user feedback signal recorded by `FeedbackStore`.
/// Privacy rule: entityId references an entity UUID, never raw narration text.
public struct FeedbackEvent: Codable, Identifiable, Sendable {
    public let id: UUID
    public let eventType: FeedbackEventType
    /// Domain type being corrected: "transaction", "merchant", "person", "relationship", "recurring", "insight".
    public let entityType: String
    /// UUID of the entity being corrected.
    public let entityId: String
    /// Transaction that triggered the event. Nil for entity-level events.
    public let transactionId: String?
    /// Previous value before correction. Nil for creation events.
    public let oldValue: String?
    /// New value after correction.
    public let newValue: String?
    /// Source of the event: "user", "pipeline", "merge".
    public let source: String?
    /// Model version active at correction time.
    public let modelVersion: String?
    /// Config version active at correction time.
    public let configVersion: String?
    /// Arbitrary structured metadata encoded as JSON.
    public let metadataJson: String?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        eventType: FeedbackEventType,
        entityType: String,
        entityId: String,
        transactionId: String? = nil,
        oldValue: String? = nil,
        newValue: String? = nil,
        source: String? = "user",
        modelVersion: String? = nil,
        configVersion: String? = nil,
        metadataJson: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.eventType = eventType
        self.entityType = entityType
        self.entityId = entityId
        self.transactionId = transactionId
        self.oldValue = oldValue
        self.newValue = newValue
        self.source = source
        self.modelVersion = modelVersion
        self.configVersion = configVersion
        self.metadataJson = metadataJson
        self.createdAt = createdAt
    }
}
