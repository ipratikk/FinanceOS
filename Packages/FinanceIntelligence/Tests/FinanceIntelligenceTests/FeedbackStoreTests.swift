@testable import FinanceIntelligence
import Foundation
import GRDB
import Testing

// MARK: - Helpers

private func makeDB() throws -> DatabaseQueue {
    let db = try DatabaseQueue(path: ":memory:")
    try db.write { database in
        try database.create(table: "intelligence_feedback_events") { table in
            table.column("id", .text).primaryKey()
            table.column("eventType", .text).notNull()
            table.column("entityType", .text).notNull()
            table.column("entityId", .text).notNull()
            table.column("transactionId", .text)
            table.column("oldValue", .text)
            table.column("newValue", .text)
            table.column("source", .text)
            table.column("modelVersion", .text)
            table.column("configVersion", .text)
            table.column("metadataJson", .text)
            table.column("createdAt", .datetime).notNull()
        }
    }
    return db
}

// MARK: - record persists an event

@Test
func feedbackStoreRecordsPersistsEvent() async throws {
    let db = try makeDB()
    let store = GRDBFeedbackStore(dbQueue: db)
    let txnId = UUID()

    let event = FeedbackEvent(
        eventType: .categoryCorrected,
        entityType: "transaction",
        entityId: txnId.uuidString,
        transactionId: txnId.uuidString,
        oldValue: "shopping",
        newValue: "food",
        modelVersion: "knn-v1",
        configVersion: "2026-06-01.v1"
    )
    try await store.record(event)

    let fetched = try await store.events(for: txnId)
    #expect(fetched.count == 1)
    #expect(fetched[0].eventType == .categoryCorrected)
    #expect(fetched[0].oldValue == "shopping")
    #expect(fetched[0].newValue == "food")
    #expect(fetched[0].modelVersion == "knn-v1")
}

// MARK: - events(ofType:) filters correctly

@Test
func feedbackStoreFiltersEventsByType() async throws {
    let db = try makeDB()
    let store = GRDBFeedbackStore(dbQueue: db)
    let txnId = UUID()

    try await store.record(FeedbackEvent(
        eventType: .categoryCorrected,
        entityType: "transaction", entityId: txnId.uuidString,
        transactionId: txnId.uuidString, newValue: "food"
    ))
    try await store.record(FeedbackEvent(
        eventType: .merchantCorrected,
        entityType: "transaction", entityId: txnId.uuidString,
        transactionId: txnId.uuidString, newValue: "Zepto"
    ))
    try await store.record(FeedbackEvent(
        eventType: .categoryCorrected,
        entityType: "transaction", entityId: UUID().uuidString, newValue: "travel"
    ))

    let categoryEvents = try await store.events(ofType: .categoryCorrected)
    let merchantEvents = try await store.events(ofType: .merchantCorrected)
    #expect(categoryEvents.count == 2)
    #expect(merchantEvents.count == 1)
    #expect(merchantEvents[0].newValue == "Zepto")
}

// MARK: - allEvents returns all records

@Test
func feedbackStoreAllEventsReturnsAll() async throws {
    let db = try makeDB()
    let store = GRDBFeedbackStore(dbQueue: db)

    for type in [FeedbackEventType.categoryCorrected, .merchantCorrected, .recurringConfirmed] {
        try await store.record(FeedbackEvent(
            eventType: type, entityType: "transaction", entityId: UUID().uuidString
        ))
    }
    let all = try await store.allEvents()
    #expect(all.count == 3)
}

// MARK: - NullFeedbackStore is a no-op

@Test
func nullFeedbackStoreIsNoOp() async throws {
    let store = NullFeedbackStore()
    let event = FeedbackEvent(
        eventType: .categoryCorrected,
        entityType: "transaction", entityId: UUID().uuidString
    )
    try await store.record(event)
    let all = try await store.allEvents()
    #expect(all.isEmpty)
}

// MARK: - Unknown eventType rawValue is skipped by toDomain

@Test
func unknownEventTypeSkippedByToDomain() async throws {
    let db = try makeDB()
    try await db.write { db in
        try db.execute(sql: """
            INSERT INTO intelligence_feedback_events
            (id, eventType, entityType, entityId, createdAt)
            VALUES (?, 'unknownType', 'transaction', 'abc', ?)
        """, arguments: [UUID().uuidString, Date()])
    }
    let store = GRDBFeedbackStore(dbQueue: db)
    let all = try await store.allEvents()
    #expect(all.isEmpty)
}
