@testable import FinanceIntelligence
import Foundation
import GRDB
import Testing

// MARK: - Test Helpers

/// Runs v11 + v12 migrations on an in-memory database for integration testing.
private func makeTestDatabase() throws -> DatabaseQueue {
    let dbQueue = try DatabaseQueue(path: ":memory:")
    try dbQueue.write { database in
        try database.create(table: "intelligence_persons") { table in
            table.column("id", .text).primaryKey()
            table.column("canonicalName", .text).notNull()
            table.column("upiHandle", .text)
            table.column("transactionCount", .integer).notNull().defaults(to: 1)
            table.column("firstSeenAt", .datetime).notNull()
            table.column("lastSeenAt", .datetime).notNull()
        }
        try database.execute(sql: """
            CREATE UNIQUE INDEX IF NOT EXISTS idx_intel_persons_upi
            ON intelligence_persons(upiHandle) WHERE upiHandle IS NOT NULL
            """)
        try database.create(table: "intelligence_person_aliases") { table in
            table.column("id", .text).primaryKey()
            table.column("personId", .text).notNull()
                .references("intelligence_persons", column: "id", onDelete: .cascade)
            table.column("alias", .text).notNull()
        }
        try database.create(index: "idx_intel_aliases_alias",
                            on: "intelligence_person_aliases",
                            columns: ["alias"], unique: true)
        try database.create(index: "idx_intel_aliases_personId",
                            on: "intelligence_person_aliases",
                            columns: ["personId"])
    }
    return dbQueue
}

private func makeRepo() throws -> GRDBIntelligencePersonRepository {
    GRDBIntelligencePersonRepository(dbQueue: try makeTestDatabase())
}

// MARK: - findOrCreate: New Person

@Test func personRepo_findOrCreate_createNewPerson() async throws {
    let repo = try makeRepo()
    let p = try await repo.findOrCreate(name: "RITIK GUPTA", upiHandle: nil, date: Date())
    #expect(p.canonicalName == "Ritik Gupta")
    #expect(p.transactionCount == 1)
    #expect(p.upiHandle == nil)
}

@Test func personRepo_findOrCreate_titleCasesName() async throws {
    let repo = try makeRepo()
    let p = try await repo.findOrCreate(name: "SEEMA GOEL", upiHandle: nil, date: Date())
    #expect(p.canonicalName == "Seema Goel")
}

@Test func personRepo_findOrCreate_storesUPIHandle() async throws {
    let repo = try makeRepo()
    let p = try await repo.findOrCreate(name: "AMAN", upiHandle: "aman@hdfc", date: Date())
    #expect(p.upiHandle == "aman@hdfc")
}

@Test func personRepo_findOrCreate_setsFirstAndLastSeen() async throws {
    let repo = try makeRepo()
    let date = Date()
    let p = try await repo.findOrCreate(name: "RAVI KUMAR", upiHandle: nil, date: date)
    #expect(p.firstSeenAt <= date)
    #expect(p.lastSeenAt <= date)
}

// MARK: - findOrCreate: Deduplication by Name

@Test func personRepo_findOrCreate_deduplicatesBySameName() async throws {
    let repo = try makeRepo()
    let date = Date()
    let p1 = try await repo.findOrCreate(name: "RITIK GUPTA", upiHandle: nil, date: date)
    let p2 = try await repo.findOrCreate(name: "RITIK GUPTA", upiHandle: nil, date: date)
    #expect(p1.id == p2.id)
}

@Test func personRepo_findOrCreate_incrementsTransactionCount() async throws {
    let repo = try makeRepo()
    let date = Date()
    _ = try await repo.findOrCreate(name: "SEEMA GOEL", upiHandle: nil, date: date)
    let p = try await repo.findOrCreate(name: "SEEMA GOEL", upiHandle: nil, date: date)
    #expect(p.transactionCount == 2)
}

@Test func personRepo_findOrCreate_stripsTitle_mr() async throws {
    let repo = try makeRepo()
    let p1 = try await repo.findOrCreate(name: "MR RITIK GUPTA", upiHandle: nil, date: Date())
    let p2 = try await repo.findOrCreate(name: "RITIK GUPTA", upiHandle: nil, date: Date())
    #expect(p1.id == p2.id)
}

@Test func personRepo_findOrCreate_stripsTitle_dr() async throws {
    let repo = try makeRepo()
    let p1 = try await repo.findOrCreate(name: "DR SHARMA", upiHandle: nil, date: Date())
    let p2 = try await repo.findOrCreate(name: "SHARMA", upiHandle: nil, date: Date())
    #expect(p1.id == p2.id)
}

@Test func personRepo_findOrCreate_distinctNamesCreateDistinctPersons() async throws {
    let repo = try makeRepo()
    let date = Date()
    let p1 = try await repo.findOrCreate(name: "RITIK GUPTA", upiHandle: nil, date: date)
    let p2 = try await repo.findOrCreate(name: "AMAN PANDEY", upiHandle: nil, date: date)
    #expect(p1.id != p2.id)
}

// MARK: - findOrCreate: Deduplication by UPI Handle

@Test func personRepo_findOrCreate_deduplicatesByUPIHandle() async throws {
    let repo = try makeRepo()
    let date = Date()
    let p1 = try await repo.findOrCreate(name: "RITIK", upiHandle: "ritik@hdfc", date: date)
    let p2 = try await repo.findOrCreate(name: "RITIK GUPTA", upiHandle: "ritik@hdfc", date: date)
    #expect(p1.id == p2.id)
}

@Test func personRepo_findOrCreate_upiHandleStoredLowercase() async throws {
    let repo = try makeRepo()
    let p = try await repo.findOrCreate(name: "ANITA", upiHandle: "ANITA@HDFC", date: Date())
    #expect(p.upiHandle == "anita@hdfc")
}

@Test func personRepo_findOrCreate_addsUPIHandleOnSubsequentCall() async throws {
    let repo = try makeRepo()
    let date = Date()
    _ = try await repo.findOrCreate(name: "VIKRAM NAIR", upiHandle: nil, date: date)
    let p = try await repo.findOrCreate(name: "VIKRAM NAIR", upiHandle: "vikram@federal", date: date)
    #expect(p.upiHandle == "vikram@federal")
}

// MARK: - fetchAll

@Test func personRepo_fetchAll_emptyInitially() async throws {
    let repo = try makeRepo()
    let all = try await repo.fetchAll()
    #expect(all.isEmpty)
}

@Test func personRepo_fetchAll_returnsAllPersons() async throws {
    let repo = try makeRepo()
    let date = Date()
    _ = try await repo.findOrCreate(name: "RITIK GUPTA", upiHandle: nil, date: date)
    _ = try await repo.findOrCreate(name: "SEEMA GOEL", upiHandle: nil, date: date)
    _ = try await repo.findOrCreate(name: "AMAN PANDEY", upiHandle: nil, date: date)
    let all = try await repo.fetchAll()
    #expect(all.count == 3)
}

@Test func personRepo_fetchAll_deduplicatedCountCorrect() async throws {
    let repo = try makeRepo()
    let date = Date()
    _ = try await repo.findOrCreate(name: "RITIK GUPTA", upiHandle: nil, date: date)
    _ = try await repo.findOrCreate(name: "RITIK GUPTA", upiHandle: nil, date: date)  // dedup
    let all = try await repo.fetchAll()
    #expect(all.count == 1)
}

// MARK: - person(forId:)

@Test func personRepo_personForId_returnsExistingPerson() async throws {
    let repo = try makeRepo()
    let created = try await repo.findOrCreate(name: "PRIYA SHARMA", upiHandle: nil, date: Date())
    let fetched = try await repo.person(forId: created.id)
    #expect(fetched?.id == created.id)
    #expect(fetched?.canonicalName == "Priya Sharma")
}

@Test func personRepo_personForId_returnsNilForUnknownID() async throws {
    let repo = try makeRepo()
    let result = try await repo.person(forId: UUID())
    #expect(result == nil)
}

// MARK: - Alias Recording

@Test func personRepo_aliases_recordedForNewPerson() async throws {
    let repo = try makeRepo()
    let p = try await repo.findOrCreate(name: "RAVI PATEL", upiHandle: nil, date: Date())
    #expect(!p.aliases.isEmpty)
}

@Test func personRepo_aliases_includeVariantsAcrossCallsBySamePerson() async throws {
    let repo = try makeRepo()
    _ = try await repo.findOrCreate(name: "RAVI PATEL", upiHandle: nil, date: Date())
    let p = try await repo.findOrCreate(name: "RAVI PATEL", upiHandle: nil, date: Date())
    // Both calls use same normalized alias → at least one alias entry
    #expect(!p.aliases.isEmpty)
}
