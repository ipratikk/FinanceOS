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
        try await dbWriter.write { db in
            // Stable key: (merchantKey, cadence) OR (personId, cadence).
            // merchantKey branch ignores personId so merchant+person dual entries collapse
            // when the same merchant's transactions are only partially person-resolved.
            // RecurringDetector assigns a fresh UUID on every run so never key on id.
            let existing: GRDBRecurringPattern? = if let key = pattern.merchantKey {
                try GRDBRecurringPattern
                    .filter(Column("merchantKey") == key && Column("cadence") == pattern.cadence.rawValue)
                    .fetchOne(db)
            } else if let pid = pattern.personId {
                try GRDBRecurringPattern
                    .filter(Column("personId") == pid && Column("cadence") == pattern.cadence.rawValue)
                    .fetchOne(db)
            } else {
                nil
            }
            if let prior = existing {
                var updated = GRDBRecurringPattern(from: pattern)
                updated.id = prior.id
                updated.createdAt = prior.createdAt
                try updated.update(db)
            } else {
                try GRDBRecurringPattern(from: pattern).insert(db)
            }
        }
    }

    public func delete(id: UUID) async throws {
        try await dbWriter.write { db in
            try GRDBRecurringPattern.filter(Column("id") == id.uuidString).deleteAll(db)
        }
    }
}
