import Foundation

public protocol RecurringPatternRepository: Sendable {
    func fetchAll() async throws -> [RecurringPattern]
    func fetch(merchantKey: String) async throws -> RecurringPattern?
    func fetch(personId: String) async throws -> RecurringPattern?
    func save(_ pattern: RecurringPattern) async throws
    func delete(id: UUID) async throws
}
