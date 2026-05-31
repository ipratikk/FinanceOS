import Foundation
import GRDB

public struct GRDBRecurringPatternRepository: RecurringPatternRepository {
    private let dbWriter: any DatabaseWriter
    public init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    public func fetchAll() async throws -> [RecurringPattern] {
        try await dbWriter.read { db in
            try GRDBRecurringPattern.fetchAll(db).compactMap { $0.toDomain() }
        }
    }

    public func fetch(merchantKey: String) async throws -> RecurringPattern? {
        try await dbWriter.read { db in
            try GRDBRecurringPattern.filter(Column("merchantKey") == merchantKey).fetchOne(db)?.toDomain()
        }
    }

    public func fetch(personId: String) async throws -> RecurringPattern? {
        try await dbWriter.read { db in
            try GRDBRecurringPattern.filter(Column("personId") == personId).fetchOne(db)?.toDomain()
        }
    }

    public func save(_ pattern: RecurringPattern) async throws {
        let grdb = GRDBRecurringPattern(from: pattern)
        try await dbWriter.write { db in try grdb.upsert(db) }
    }

    public func delete(id: UUID) async throws {
        try await dbWriter.write { db in
            try GRDBRecurringPattern.filter(Column("id") == id.uuidString).deleteAll(db)
        }
    }
}
