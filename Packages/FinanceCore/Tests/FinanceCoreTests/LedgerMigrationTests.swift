@testable import FinanceCore
import Foundation
import GRDB
import Testing

@Test
func intelligenceInferenceEventsTableIsCreatedByMigration() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { db in
        try db.execute(sql: """
            INSERT INTO intelligence_inference_events
                (id, stage, source, confidenceKind, createdAt)
            VALUES ('evt-1', 'ruleCategorization', 'structuralRule', 'deterministic',
                    '2026-06-01T00:00:00Z')
        """)
    }
    let count = try dbQueue.read { db in
        try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM intelligence_inference_events") ?? 0
    }
    #expect(count == 1)
}

@Test
func inferenceEventsConfidenceKindCheckConstraintRejects() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    #expect(throws: (any Error).self) {
        try dbQueue.write { db in
            try db.execute(sql: """
                INSERT INTO intelligence_inference_events
                    (id, stage, source, confidenceKind, createdAt)
                VALUES ('evt-bad', 'ruleCategorization', 'structuralRule', 'invalid_kind',
                        '2026-06-01T00:00:00Z')
            """)
        }
    }
}

@Test
func ledgerTableIsCreatedByMigration() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    let ledgerCount = try dbQueue.read { database in
        try Ledger.fetchCount(database)
    }

    #expect(ledgerCount == 0)
}

@Test
func ledgersOfBothKindsCanBeInsertedAfterMigration() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let bank = try #require(dbQueue.read { database in
        try Bank.fetchAll(database).first
    })

    let accountLedger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Savings Account",
        accountType: "savings"
    )

    let cardLedger = Ledger(
        bankId: bank.id,
        kind: .creditCard,
        displayName: "Platinum Card",
        cardType: .other,
        linkedLedgerId: accountLedger.id
    )

    try dbQueue.write { database in
        try accountLedger.insert(database)
        try cardLedger.insert(database)
    }

    let ledgerCount = try dbQueue.read { database in
        try Ledger.fetchCount(database)
    }

    #expect(ledgerCount == 2)
}

@Test
func ledgerPropertiesArePersistedCorrectly() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let bank = try #require(dbQueue.read { database in
        try Bank.fetchAll(database).first
    })

    let original = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Checking Account",
        last4: "1234",
        nickname: "Primary",
        ownerName: "Test User",
        accountType: "checking"
    )

    try dbQueue.write { database in
        try original.insert(database)
    }

    let fetched = try dbQueue.read { database in
        try Ledger.fetchOne(database, id: original.id)
    }

    #expect(fetched != nil)
    #expect(fetched?.bankId == original.bankId)
    #expect(fetched?.displayName == original.displayName)
    #expect(fetched?.last4 == original.last4)
    #expect(fetched?.nickname == original.nickname)
    #expect(fetched?.ownerName == original.ownerName)
    #expect(fetched?.accountType == original.accountType)
    #expect(fetched?.kind == .bankAccount)
}

@Test
func cardLedgerPropertiesArePersistedCorrectly() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let bank = try #require(dbQueue.read { database in
        try Bank.fetchAll(database).first
    })

    let accountLedger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Bank Account"
    )

    let cardLedger = Ledger(
        bankId: bank.id,
        kind: .creditCard,
        displayName: "Travel Card",
        last4: "5678",
        cardType: .other,
        linkedLedgerId: accountLedger.id
    )

    try dbQueue.write { database in
        try accountLedger.insert(database)
        try cardLedger.insert(database)
    }

    let fetched = try dbQueue.read { database in
        try Ledger.fetchOne(database, id: cardLedger.id)
    }

    #expect(fetched != nil)
    #expect(fetched?.bankId == cardLedger.bankId)
    #expect(fetched?.displayName == cardLedger.displayName)
    #expect(fetched?.cardType == cardLedger.cardType)
    #expect(fetched?.linkedLedgerId == accountLedger.id)
    #expect(fetched?.kind == .creditCard)
}

@Test
func v21ModelMetadataTableExpandedWithFullSchema() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)
    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { db in
        // Two rows with the same modelName must succeed (no UNIQUE constraint).
        try db.execute(sql: """
            INSERT INTO intelligence_model_metadata
                (id, modelName, modelType, modelVersion, trainedAt, trainingExampleCount)
            VALUES
                ('m1', 'personalized-knn', 'knn', 'v1', '2026-06-01T10:00:00Z', 100),
                ('m2', 'personalized-knn', 'knn', 'v2', '2026-06-01T11:00:00Z', 150)
        """)
    }
    let count = try dbQueue.read { db in
        try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM intelligence_model_metadata") ?? 0
    }
    #expect(count == 2)
}
