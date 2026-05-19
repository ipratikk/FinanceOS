@testable import FinanceCore
import GRDB
import Testing

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

    let bank = try dbQueue.read { database in
        try Bank.fetchAll(database).first!
    }

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
        cardType: "credit",
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

    let bank = try dbQueue.read { database in
        try Bank.fetchAll(database).first!
    }

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

    let bank = try dbQueue.read { database in
        try Bank.fetchAll(database).first!
    }

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
        cardType: "credit",
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
