import FinanceCore
import Foundation
import GRDB

/// GRDB-backed implementation of `IntelligencePersonRepository`.
///
/// Persists person entities to `intelligence_persons` and aliases to
/// `intelligence_person_aliases`. Deduplicates by normalized canonical name and UPI handle.
///
/// All write operations run in a single serialized GRDB write transaction.
public final class GRDBIntelligencePersonRepository: @unchecked Sendable,
                                                      IntelligencePersonRepository {
    private let dbQueue: DatabaseQueue
    private let logger = FinanceLogger.repository

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func findOrCreate(name: String, upiHandle: String?, date: Date) async throws -> Person {
        let normalized = PersonNameNormalizer.normalize(name)
        return try await dbQueue.write { [self] database in
            // Check by alias index first (covers normalized name variants)
            if let existingId = try self.personId(forAlias: normalized, in: database) {
                return try self.updatePerson(
                    id: existingId, rawName: name, upiHandle: upiHandle,
                    date: date, in: database
                )
            }
            // Check by UPI handle if provided
            if let handle = upiHandle?.lowercased(),
               let row = try GRDBIntelligencePerson
                   .filter(GRDBIntelligencePerson.Columns.upiHandle == handle)
                   .fetchOne(database) {
                return try self.updatePerson(
                    id: row.id, rawName: name, upiHandle: upiHandle,
                    date: date, in: database
                )
            }
            return try self.createPerson(
                canonicalName: PersonNameNormalizer.titleCase(name),
                rawName: name, upiHandle: upiHandle, date: date, in: database
            )
        }
    }

    public func fetchAll() async throws -> [Person] {
        try await dbQueue.read { database in
            let rows = try GRDBIntelligencePerson.fetchAll(database)
            return try rows.map { row in
                let aliases = try GRDBIntelligencePersonAlias
                    .filter(GRDBIntelligencePersonAlias.Columns.personId == row.id)
                    .fetchAll(database)
                    .map(\.alias)
                return row.toPerson(aliases: aliases)
            }
        }
    }

    public func person(forId id: UUID) async throws -> Person? {
        try await dbQueue.read { database in
            guard let row = try GRDBIntelligencePerson
                .filter(GRDBIntelligencePerson.Columns.id == id).fetchOne(database) else {
                return nil
            }
            let aliases = try GRDBIntelligencePersonAlias
                .filter(GRDBIntelligencePersonAlias.Columns.personId == id)
                .fetchAll(database)
                .map(\.alias)
            return row.toPerson(aliases: aliases)
        }
    }
}

// MARK: - Private Write Helpers

private extension GRDBIntelligencePersonRepository {
    func personId(forAlias alias: String, in database: Database) throws -> UUID? {
        try GRDBIntelligencePersonAlias
            .filter(GRDBIntelligencePersonAlias.Columns.alias == alias)
            .fetchOne(database)
            .map(\.personId)
    }

    func updatePerson(
        id: UUID,
        rawName: String,
        upiHandle: String?,
        date: Date,
        in database: Database
    ) throws -> Person {
        guard var row = try GRDBIntelligencePerson
            .filter(GRDBIntelligencePerson.Columns.id == id).fetchOne(database) else {
            throw RepositoryError.notFound(entity: "IntelligencePerson", id: id.uuidString)
        }
        row.transactionCount += 1
        row.lastSeenAt = date
        if row.upiHandle == nil, let handle = upiHandle {
            row.upiHandle = handle.lowercased()
        }
        try row.update(database)
        try insertAliasIfNeeded(personId: id, alias: rawName, in: database)
        logger.logDebug("Updated intelligence_person", ["id": id.uuidString])
        let aliases = try GRDBIntelligencePersonAlias
            .filter(GRDBIntelligencePersonAlias.Columns.personId == id)
            .fetchAll(database).map(\.alias)
        return row.toPerson(aliases: aliases)
    }

    func createPerson(
        canonicalName: String,
        rawName: String,
        upiHandle: String?,
        date: Date,
        in database: Database
    ) throws -> Person {
        let row = GRDBIntelligencePerson(
            id: UUID(),
            canonicalName: canonicalName,
            upiHandle: upiHandle?.lowercased(),
            transactionCount: 1,
            firstSeenAt: date,
            lastSeenAt: date
        )
        try row.insert(database)
        let normalized = PersonNameNormalizer.normalize(rawName)
        try insertAliasIfNeeded(personId: row.id, alias: normalized, in: database)
        if rawName != normalized {
            try insertAliasIfNeeded(personId: row.id, alias: rawName, in: database)
        }
        logger.logInfo("Created intelligence_person", ["id": row.id.uuidString, "name": canonicalName])
        return row.toPerson(aliases: [normalized])
    }

    func insertAliasIfNeeded(personId: UUID, alias: String, in database: Database) throws {
        let exists = try GRDBIntelligencePersonAlias
            .filter(GRDBIntelligencePersonAlias.Columns.alias == alias)
            .fetchCount(database) > 0
        guard !exists else { return }
        let aliasRow = GRDBIntelligencePersonAlias(id: UUID(), personId: personId, alias: alias)
        try aliasRow.insert(database)
    }
}

// MARK: - Name Normalization (shared logic, mirrors PersonEntityStore)

enum PersonNameNormalizer {
    static func normalize(_ name: String) -> String {
        var result = name.uppercased()
        for title in ["MR ", "MRS ", "MS ", "DR ", "PROF ", "SHRI ", "SMT ", "KUM "]
            where result.hasPrefix(title) {
            result = String(result.dropFirst(title.count))
        }
        return result.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")
    }

    static func titleCase(_ input: String) -> String {
        input.components(separatedBy: " ")
            .map { $0.isEmpty ? $0 : $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}
