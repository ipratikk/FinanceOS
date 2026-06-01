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
    private let feedbackStore: any FeedbackStore
    private let deduplicator = PersonDeduplicator()
    private let logger = FinanceLogger.repository

    public init(dbQueue: DatabaseQueue, feedbackStore: (any FeedbackStore)? = nil) {
        self.dbQueue = dbQueue
        self.feedbackStore = feedbackStore ?? NullFeedbackStore()
    }

    public func findOrCreate(name: String, upiHandle: String?, date: Date) async throws -> Person {
        let sanitizedName = NameSanitizer.sanitize(name)
        let effectiveName = sanitizedName.isEmpty ? name : sanitizedName
        let normalized = PersonNameNormalizer.normalize(effectiveName)

        // Return (person, mergeInfo?) from write — avoid mutable capture across concurrency boundary.
        typealias WriteResult = (person: Person, mergedIntoId: UUID?, fromName: String?, canonicalName: String?)
        let result: WriteResult = try await dbQueue.write { [self] database in
            if let existingId = try personId(forAlias: normalized, in: database) {
                let p = try updatePerson(id: existingId, rawName: effectiveName, upiHandle: upiHandle, date: date, in: database)
                return (p, nil, nil, nil)
            }
            if sanitizedName != name {
                let originalNormalized = PersonNameNormalizer.normalize(name)
                if let existingId = try personId(forAlias: originalNormalized, in: database) {
                    let p = try updatePerson(id: existingId, rawName: effectiveName, upiHandle: upiHandle, date: date, in: database)
                    return (p, nil, nil, nil)
                }
            }
            if let handle = upiHandle?.lowercased(),
               let row = try GRDBIntelligencePerson
               .filter(GRDBIntelligencePerson.Columns.upiHandle == handle)
               .fetchOne(database) {
                let p = try updatePerson(id: row.id, rawName: effectiveName, upiHandle: upiHandle, date: date, in: database)
                return (p, nil, nil, nil)
            }
            // Fuzzy dedup: check for near-duplicate person before creating a new record
            if let candidate = try findFuzzyCandidate(for: effectiveName, in: database),
               candidate.matchType.isAutoMergeCandidate {
                let p = try updatePerson(id: candidate.existingId, rawName: effectiveName, upiHandle: upiHandle, date: date, in: database)
                return (p, candidate.existingId, effectiveName, candidate.existingName)
            }
            let p = try createPerson(canonicalName: PersonNameNormalizer.titleCase(effectiveName),
                                     rawName: effectiveName, upiHandle: upiHandle, date: date, in: database)
            return (p, nil, nil, nil)
        }
        if let intoId = result.mergedIntoId, let fromName = result.fromName, let canonical = result.canonicalName {
            logger.logInfo("Person auto-merged via fuzzy dedup",
                           ["intoId": intoId.uuidString, "fromName": fromName, "canonicalName": canonical])
            try? await feedbackStore.record(FeedbackEvent(
                eventType: .personMerged,
                entityType: "person",
                entityId: intoId.uuidString,
                oldValue: fromName,
                newValue: canonical
            ))
        }
        return result.person
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

    public func update(_ person: Person) async throws {
        try await dbQueue.write { database in
            guard var row = try GRDBIntelligencePerson
                .filter(GRDBIntelligencePerson.Columns.id == person.id.uuidString)
                .fetchOne(database) else { return }
            row.canonicalName = person.canonicalName
            row.upiHandle = person.upiHandle
            try row.update(database)
        }
    }

    public func delete(id: UUID) async throws {
        try await dbQueue.write { database in
            try GRDBIntelligencePerson
                .filter(GRDBIntelligencePerson.Columns.id == id.uuidString)
                .deleteAll(database)
        }
    }
}

// MARK: - Fuzzy Dedup

private extension GRDBIntelligencePersonRepository {
    /// Returns the best auto-merge candidate for `name` among all existing persons, or nil.
    /// Only returns candidates with `isAutoMergeCandidate == true` (exact or strong match).
    /// Possible-match candidates are logged for debug only and not returned.
    func findFuzzyCandidate(for name: String, in database: Database) throws -> PersonDeduplicator.Candidate? {
        let allRows = try GRDBIntelligencePerson.fetchAll(database)
        let allPersons = allRows.map { $0.toPerson(aliases: []) }
        let candidates = deduplicator.findCandidates(for: name, in: allPersons)
        for candidate in candidates where candidate.matchType == .possibleMatch {
            logger.logDebug("Person dedup possible match (review required)", [
                "input": name,
                "existingId": candidate.existingId.uuidString,
                "existingName": candidate.existingName,
                "jaccard": String(format: "%.2f", candidate.jaccardSimilarity ?? 0)
            ])
        }
        return candidates.first(where: { $0.matchType.isAutoMergeCandidate })
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
