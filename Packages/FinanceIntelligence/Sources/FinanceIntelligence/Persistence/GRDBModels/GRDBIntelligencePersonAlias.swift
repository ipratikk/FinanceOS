import Foundation
import GRDB

/// GRDB row model for the `intelligence_person_aliases` table.
/// Each row records one name variant (raw alias) observed for a person.
struct GRDBIntelligencePersonAlias: FetchableRecord, PersistableRecord, Sendable, Codable {
    static let databaseTableName = "intelligence_person_aliases"

    var id: UUID
    var personId: UUID
    var alias: String

    enum CodingKeys: String, CodingKey {
        case id, personId, alias
    }

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let personId = Column(CodingKeys.personId)
        static let alias = Column(CodingKeys.alias)
    }
}
