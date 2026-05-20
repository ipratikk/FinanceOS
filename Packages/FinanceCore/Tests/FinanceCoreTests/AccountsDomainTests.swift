@testable import FinanceCore
import Foundation
import GRDB
import Testing

@Test
func bankSeedingCreatesExpectedBanks() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(
        in: &migrator
    )

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let banks = try dbQueue.read { database in
        try Bank.fetchAll(database)
    }

    #expect(banks.count == 4)
    #expect(banks.contains { $0.name == "HDFC Bank" })
    #expect(banks.contains { $0.name == "ICICI Bank" })
    #expect(banks.contains { $0.name == "American Express" })
    #expect(banks.contains { $0.name == "Scapia" })
}

@Test
func ledgersCanBeLinkedAcrossBankAccountAndCard() throws {
    let dbQueue = try migratedAccountsDatabase()
    let fixtures = try linkedLedgerFixtures(in: dbQueue)

    try dbQueue.write { database in
        try fixtures.hdfcAccount.insert(database)
        try fixtures.iciciAccount.insert(database)
        try fixtures.hdfcRegalia.insert(database)
        try fixtures.iciciCoral.insert(database)
    }

    let ledgers = try dbQueue.read { database in
        try Ledger.fetchAll(database)
    }

    let accountLedgers = ledgers.filter { $0.kind == .bankAccount }
    let cardLedgers = ledgers.filter { $0.kind == .creditCard }

    #expect(accountLedgers.count == 2)
    #expect(cardLedgers.count == 2)

    let fetchedRegalia = try #require(cardLedgers.first { $0.displayName == "HDFC Regalia" })
    let fetchedCoral = try #require(cardLedgers.first { $0.displayName == "ICICI Coral" })

    #expect(fetchedRegalia.linkedLedgerId == fixtures.hdfcAccount.id)
    #expect(fetchedCoral.linkedLedgerId == fixtures.iciciAccount.id)
}

private func migratedAccountsDatabase() throws -> DatabaseQueue {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)
    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }
    return dbQueue
}

private func linkedLedgerFixtures(in dbQueue: DatabaseQueue) throws -> LinkedLedgerFixtures {
    let banks = try dbQueue.read { database in
        try Bank.fetchAll(database)
    }
    let hdfcBank = try #require(banks.first { $0.name == "HDFC Bank" })
    let iciciBank = try #require(banks.first { $0.name == "ICICI Bank" })
    return LinkedLedgerFixtures(hdfcBank: hdfcBank, iciciBank: iciciBank)
}

private struct LinkedLedgerFixtures {
    let hdfcAccount: Ledger
    let iciciAccount: Ledger
    let hdfcRegalia: Ledger
    let iciciCoral: Ledger

    init(hdfcBank: Bank, iciciBank: Bank) {
        let hdfcAccount = Ledger(
            bankId: hdfcBank.id,
            kind: .bankAccount,
            displayName: "HDFC Bank Account"
        )
        let iciciAccount = Ledger(
            bankId: iciciBank.id,
            kind: .bankAccount,
            displayName: "ICICI Bank Account"
        )
        self.hdfcAccount = hdfcAccount
        self.iciciAccount = iciciAccount
        hdfcRegalia = Ledger(
            bankId: hdfcBank.id,
            kind: .creditCard,
            displayName: "HDFC Regalia",
            linkedLedgerId: hdfcAccount.id
        )
        iciciCoral = Ledger(
            bankId: iciciBank.id,
            kind: .creditCard,
            displayName: "ICICI Coral",
            linkedLedgerId: iciciAccount.id
        )
    }
}

@Test
func bankSeedingIsIdempotent() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(
        in: &migrator
    )

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
        try DatabaseSeeder.seedBanks(in: database)
    }

    let banksCount = try dbQueue.read { database in
        try Bank.fetchCount(database)
    }

    #expect(banksCount == 4)
}
