import Foundation
import GRDB

/// GRDB row model for the `intelligence_persons` table.
/// Converts to/from the domain `Person` type for use in repositories.
struct GRDBIntelligencePerson: FetchableRecord, PersistableRecord, Sendable, Codable {
    static let databaseTableName = "intelligence_persons"

    var id: UUID
    var canonicalName: String
    var upiHandle: String?
    var transactionCount: Int
    var firstSeenAt: Date
    var lastSeenAt: Date

    enum CodingKeys: String, CodingKey {
        case id, canonicalName, upiHandle, transactionCount, firstSeenAt, lastSeenAt
    }

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let canonicalName = Column(CodingKeys.canonicalName)
        static let upiHandle = Column(CodingKeys.upiHandle)
        static let transactionCount = Column(CodingKeys.transactionCount)
        static let firstSeenAt = Column(CodingKeys.firstSeenAt)
        static let lastSeenAt = Column(CodingKeys.lastSeenAt)
    }

    /// Converts to the public domain `Person` with the provided alias strings.
    func toPerson(aliases: [String]) -> Person {
        Person(
            id: id,
            canonicalName: canonicalName,
            aliases: aliases,
            upiHandle: upiHandle,
            transactionCount: transactionCount,
            firstSeenAt: firstSeenAt,
            lastSeenAt: lastSeenAt
        )
    }

    /// Creates a `GRDBIntelligencePerson` from a domain `Person`.
    static func from(_ person: Person) -> GRDBIntelligencePerson {
        GRDBIntelligencePerson(
            id: person.id,
            canonicalName: person.canonicalName,
            upiHandle: person.upiHandle,
            transactionCount: person.transactionCount,
            firstSeenAt: person.firstSeenAt,
            lastSeenAt: person.lastSeenAt
        )
    }
}
