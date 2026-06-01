import Foundation
import GRDB

struct GRDBFeedbackEvent: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "intelligence_feedback_events"

    let id: UUID
    let eventType: String
    let entityType: String
    let entityId: String
    let transactionId: String?
    let oldValue: String?
    let newValue: String?
    let source: String?
    let modelVersion: String?
    let configVersion: String?
    let metadataJson: String?
    let createdAt: Date
}

extension GRDBFeedbackEvent {
    init(_ event: FeedbackEvent) {
        id = event.id
        eventType = event.eventType.rawValue
        entityType = event.entityType
        entityId = event.entityId
        transactionId = event.transactionId
        oldValue = event.oldValue
        newValue = event.newValue
        source = event.source
        modelVersion = event.modelVersion
        configVersion = event.configVersion
        metadataJson = event.metadataJson
        createdAt = event.createdAt
    }

    func toDomain() -> FeedbackEvent? {
        guard let type = FeedbackEventType(rawValue: eventType) else { return nil }
        return FeedbackEvent(
            id: id, eventType: type, entityType: entityType, entityId: entityId,
            transactionId: transactionId, oldValue: oldValue, newValue: newValue,
            source: source, modelVersion: modelVersion, configVersion: configVersion,
            metadataJson: metadataJson, createdAt: createdAt
        )
    }
}
