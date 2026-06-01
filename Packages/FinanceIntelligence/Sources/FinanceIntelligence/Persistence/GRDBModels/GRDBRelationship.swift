import Foundation
import GRDB

struct GRDBRelationship: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "relationships"

    var id: String
    var fromPersonId: String?
    var toPersonId: String?
    var relationshipType: String
    var confidence: Double
    var evidenceCount: Int
    var inferredSignals: String
    var createdAt: Date
    var updatedAt: Date
    var verificationState: String

    init(from relationship: Relationship) {
        id = relationship.id.uuidString
        fromPersonId = relationship.fromPersonId
        toPersonId = relationship.toPersonId
        relationshipType = relationship.type.rawValue
        confidence = relationship.confidence
        evidenceCount = relationship.evidenceCount
        inferredSignals = (try? String(data: JSONEncoder().encode(
            relationship.signals.map(\.rawValue)
        ), encoding: .utf8)) ?? "[]"
        createdAt = relationship.createdAt
        updatedAt = relationship.updatedAt
        verificationState = relationship.verificationState.rawValue
    }

    func toDomain() -> Relationship? {
        guard let uuid = UUID(uuidString: id),
              let type = RelationshipType(rawValue: relationshipType) else { return nil }
        let signals = (inferredSignals.data(using: .utf8))
            .flatMap { try? JSONDecoder().decode([String].self, from: $0) }?
            .compactMap { RelationshipSignal(rawValue: $0) } ?? []
        let state = RelationshipVerificationState(rawValue: verificationState) ?? .inferred
        return Relationship(
            id: uuid, fromPersonId: fromPersonId, toPersonId: toPersonId,
            type: type, confidence: confidence, evidenceCount: evidenceCount,
            signals: signals, createdAt: createdAt, updatedAt: updatedAt,
            verificationState: state
        )
    }
}
