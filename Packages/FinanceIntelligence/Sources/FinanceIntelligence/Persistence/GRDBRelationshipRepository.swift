import Foundation
import GRDB

public struct GRDBRelationshipRepository: RelationshipRepository {
    private let dbWriter: any DatabaseWriter
    public init(dbWriter: any DatabaseWriter) { self.dbWriter = dbWriter }

    public func fetchAll() async throws -> [Relationship] {
        try await dbWriter.read { db in
            try GRDBRelationship.fetchAll(db).compactMap { $0.toDomain() }
        }
    }
    public func fetch(toPersonId: String) async throws -> Relationship? {
        try await dbWriter.read { db in
            try GRDBRelationship.filter(Column("toPersonId") == toPersonId).fetchOne(db)?.toDomain()
        }
    }
    public func save(_ relationship: Relationship) async throws {
        let grdb = GRDBRelationship(from: relationship)
        try await dbWriter.write { db in try grdb.upsert(db) }
    }
    public func delete(id: UUID) async throws {
        try await dbWriter.write { db in
            try GRDBRelationship.filter(Column("id") == id.uuidString).deleteAll(db)
        }
    }
}
