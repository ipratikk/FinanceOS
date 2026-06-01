import Foundation
import GRDB

/// GRDB-backed `FeedbackStore` that persists events to `intelligence_feedback_events`.
public final class GRDBFeedbackStore: FeedbackStore, @unchecked Sendable {
    private let dbQueue: any DatabaseWriter

    public init(dbQueue: any DatabaseWriter) {
        self.dbQueue = dbQueue
    }

    public func record(_ event: FeedbackEvent) async throws {
        try await dbQueue.write { db in
            try GRDBFeedbackEvent(event).insert(db)
        }
    }

    public func events(for transactionId: UUID) async throws -> [FeedbackEvent] {
        try await dbQueue.read { db in
            let rows = try GRDBFeedbackEvent
                .filter(Column("transactionId") == transactionId.uuidString)
                .order(Column("createdAt").desc)
                .fetchAll(db)
            return rows.compactMap { $0.toDomain() }
        }
    }

    public func events(ofType type: FeedbackEventType) async throws -> [FeedbackEvent] {
        try await dbQueue.read { db in
            let rows = try GRDBFeedbackEvent
                .filter(Column("eventType") == type.rawValue)
                .order(Column("createdAt").desc)
                .fetchAll(db)
            return rows.compactMap { $0.toDomain() }
        }
    }

    public func allEvents() async throws -> [FeedbackEvent] {
        try await dbQueue.read { db in
            let rows = try GRDBFeedbackEvent
                .order(Column("createdAt").desc)
                .fetchAll(db)
            return rows.compactMap { $0.toDomain() }
        }
    }
}
