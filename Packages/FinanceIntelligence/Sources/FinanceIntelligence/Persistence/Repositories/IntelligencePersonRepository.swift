import Foundation

/// Persistence contract for person entities resolved from transaction narrations.
///
/// Conforming types must deduplicate persons by normalized name and UPI handle.
/// The in-memory `PersonEntityStore` and `GRDBIntelligencePersonRepository` both conform.
public protocol IntelligencePersonRepository: Sendable {
    /// Returns an existing person matching `name` (normalized) or `upiHandle`, or creates one.
    /// Updates `transactionCount` and `lastSeenAt` on each call for existing persons.
    func findOrCreate(name: String, upiHandle: String?, date: Date) async throws -> Person

    /// Returns all known persons.
    func fetchAll() async throws -> [Person]

    /// Returns the person with the given ID, or nil if not found.
    func person(forId id: UUID) async throws -> Person?
}
