import Foundation

/// A resolved person entity extracted from UPI/NEFT/IMPS transfer narrations.
/// Persons are deduplicated by normalized name and UPI handle within a session.
///
/// In Phase 2, persons are ephemeral (in-memory only). Phase 3 backs this with GRDB.
public struct Person: Identifiable, Sendable, Codable {
    /// Stable UUID assigned on first encounter.
    public let id: UUID
    /// Title-cased canonical name (e.g. "Ritik Gupta"). Updated when a cleaner variant is seen.
    public var canonicalName: String
    /// All raw name strings seen for this person across transactions.
    public var aliases: [String]
    /// UPI virtual payment address (e.g. "ritikgupta@upi"), if known.
    public var upiHandle: String?
    /// Number of transactions involving this person.
    public var transactionCount: Int
    /// Date of the first transaction seen.
    public var firstSeenAt: Date
    /// Date of the most recent transaction seen.
    public var lastSeenAt: Date

    public init(
        id: UUID = UUID(),
        canonicalName: String,
        aliases: [String] = [],
        upiHandle: String? = nil,
        transactionCount: Int = 1,
        firstSeenAt: Date,
        lastSeenAt: Date
    ) {
        self.id = id
        self.canonicalName = canonicalName
        self.aliases = aliases
        self.upiHandle = upiHandle
        self.transactionCount = transactionCount
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
    }
}
