@testable import FinanceCore
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
    #expect(banks.contains { $0.name == "HDFC" })
    #expect(banks.contains { $0.name == "ICICI" })
    #expect(banks.contains { $0.name == "Amex" })
    #expect(banks.contains { $0.name == "Scapia" })
}

@Test
func ledgersCanBeLinkedAcrossBankAccountAndCard() throws {
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

    let hdfcBank = try #require(banks.first { $0.name == "HDFC" })
    let iciciBank = try #require(banks.first { $0.name == "ICICI" })

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

    try dbQueue.write { database in
        try hdfcAccount.insert(database)
        try iciciAccount.insert(database)
    }

    let hdfcRegalia = Ledger(
        bankId: hdfcBank.id,
        kind: .creditCard,
        displayName: "HDFC Regalia",
        linkedLedgerId: hdfcAccount.id
    )

    let iciciCoral = Ledger(
        bankId: iciciBank.id,
        kind: .creditCard,
        displayName: "ICICI Coral",
        linkedLedgerId: iciciAccount.id
    )

    try dbQueue.write { database in
        try hdfcRegalia.insert(database)
        try iciciCoral.insert(database)
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

    #expect(fetchedRegalia.linkedLedgerId == hdfcAccount.id)
    #expect(fetchedCoral.linkedLedgerId == iciciAccount.id)
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
