@testable import FinanceCore
import Foundation
import GRDB
import Testing

@Test
func ledgerRepositoryCRUD() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let repo = GRDBLedgerRepository(dbQueue: dbQueue)

    let bank = try await dbQueue.read { database in
        try Bank.fetchAll(database).first!
    }

    let ledger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Test Account"
    )

    try await repo.insert(ledger)

    let fetched = try await repo.fetchLedger(id: ledger.id)
    #expect(fetched != nil)
    #expect(fetched?.displayName == ledger.displayName)
}

@Test
func ledgerRepositoryFetchByKind() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let repo = GRDBLedgerRepository(dbQueue: dbQueue)

    let bank = try await dbQueue.read { database in
        try Bank.fetchAll(database).first!
    }

    let account = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Account"
    )

    let card = Ledger(
        bankId: bank.id,
        kind: .creditCard,
        displayName: "Card"
    )

    try await repo.insert(account)
    try await repo.insert(card)

    let accounts = try await repo.fetchLedgers(kind: .bankAccount)
    let cards = try await repo.fetchLedgers(kind: .creditCard)

    #expect(accounts.count == 1)
    #expect(cards.count == 1)
    #expect(accounts[0].kind == .bankAccount)
    #expect(cards[0].kind == .creditCard)
}

@Test
func ledgerRepositoryFetchByBankAndKind() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let repo = GRDBLedgerRepository(dbQueue: dbQueue)

    let banks = try await dbQueue.read { database in
        try Bank.fetchAll(database)
    }

    guard banks.count >= 2 else {
        fatalError("Need at least 2 banks")
    }

    let bank1 = banks[0]
    let bank2 = banks[1]

    let ledger1 = Ledger(
        bankId: bank1.id,
        kind: .creditCard,
        displayName: "Card 1"
    )

    let ledger2 = Ledger(
        bankId: bank2.id,
        kind: .creditCard,
        displayName: "Card 2"
    )

    try await repo.insert(ledger1)
    try await repo.insert(ledger2)

    let bank1Cards = try await repo.fetchLedgers(bankId: bank1.id, kind: .creditCard)
    let bank2Cards = try await repo.fetchLedgers(bankId: bank2.id, kind: .creditCard)

    #expect(bank1Cards.count == 1)
    #expect(bank2Cards.count == 1)
    #expect(bank1Cards[0].id == ledger1.id)
    #expect(bank2Cards[0].id == ledger2.id)
}

@Test
func ledgerRepositoryUpdate() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let repo = GRDBLedgerRepository(dbQueue: dbQueue)

    let bank = try await dbQueue.read { database in
        try Bank.fetchAll(database).first!
    }

    let ledger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Original"
    )

    try await repo.insert(ledger)

    let updated = Ledger(
        id: ledger.id,
        bankId: ledger.bankId,
        kind: ledger.kind,
        displayName: "Updated"
    )

    try await repo.update(updated)

    let fetched = try await repo.fetchLedger(id: ledger.id)
    #expect(fetched?.displayName == "Updated")
}

@Test
func ledgerRepositoryArchive() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let repo = GRDBLedgerRepository(dbQueue: dbQueue)

    let bank = try await dbQueue.read { database in
        try Bank.fetchAll(database).first!
    }

    let ledger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Test"
    )

    try await repo.insert(ledger)

    let activeBefore = try await repo.fetchLedgers()
    #expect(activeBefore.count == 1)

    try await repo.archive(id: ledger.id)

    let activeAfter = try await repo.fetchLedgers()
    #expect(activeAfter.count == 0)

    let archived = try await repo.fetchLedger(id: ledger.id)
    #expect(archived?.isArchived == true)
}

@Test
func ledgerRepositoryDeleteBlocked() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let repo = GRDBLedgerRepository(dbQueue: dbQueue)

    let bank = try await dbQueue.read { database in
        try Bank.fetchAll(database).first!
    }

    let ledger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Test Account With Transactions"
    )
    try await repo.insert(ledger)

    // Insert a transaction referencing this ledger via ledgerId.
    // accountID must be non-null to satisfy the schema check constraint.
    let txn = Transaction(
        ledgerId: ledger.id,
        accountID: ledger.id,
        postedAt: Date(timeIntervalSince1970: 0),
        description: "Seed Transaction",
        amountMinorUnits: 5000,
        currencyCode: "INR",
        transactionType: .debit
    )

    try await dbQueue.write { database in
        try txn.insert(database)
    }

    do {
        try await repo.delete(id: ledger.id)
        fatalError("Should have thrown")
    } catch let error as RepositoryError {
        if case .deleteFailed = error {
            // Expected - cannot delete ledger with transactions
        } else {
            fatalError("Wrong error type")
        }
    }
}
