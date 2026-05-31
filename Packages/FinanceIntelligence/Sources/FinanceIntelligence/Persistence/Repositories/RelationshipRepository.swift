import Foundation

public protocol RelationshipRepository: Sendable {
    func fetchAll() async throws -> [Relationship]
    func fetch(toPersonId: String) async throws -> Relationship?
    func save(_ relationship: Relationship) async throws
    func delete(id: UUID) async throws
}
