@testable import FinanceCore
import Foundation
import GRDB
import Testing

@Test
func v24MigrationCreatesFeedbackEventsTable() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)
    let db = try DatabaseQueue()
    try migrator.migrate(db)

    let exists = try await db.read { try $0.tableExists("intelligence_feedback_events") }
    #expect(exists)

    let cols = try await db.read { try $0.columns(in: "intelligence_feedback_events").map(\.name) }
    #expect(cols.contains("id"))
    #expect(cols.contains("eventType"))
    #expect(cols.contains("entityType"))
    #expect(cols.contains("entityId"))
    #expect(cols.contains("transactionId"))
    #expect(cols.contains("createdAt"))
}
