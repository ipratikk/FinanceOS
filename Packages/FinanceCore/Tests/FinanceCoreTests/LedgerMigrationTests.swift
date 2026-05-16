@testable import FinanceCore
import GRDB
import Testing

@Test
func ledgerMigrationBackfillsAccountsAndCards() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
        try DatabaseSeeder.seedAccounts(in: database)
        try DatabaseSeeder.seedCards(in: database)
        try DatabaseSeeder.seedTransactions(in: database)
    }

    let accountCount = try dbQueue.read { database in
        try Account.fetchCount(database)
    }

    let cardCount = try dbQueue.read { database in
        try Card.fetchCount(database)
    }

    let ledgerCount = try dbQueue.read { database in
        try Ledger.fetchCount(database)
    }

    #expect(ledgerCount == accountCount + cardCount)
}

@Test
func ledgerMigrationPopulatesTransactionLedgerId() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
        try DatabaseSeeder.seedAccounts(in: database)
        try DatabaseSeeder.seedCards(in: database)
        try DatabaseSeeder.seedTransactions(in: database)
    }

    let transactionsWithLedgerId = try dbQueue.read { database in
        try Transaction
            .filter(Transaction.Columns.ledgerId != nil)
            .fetchCount(database)
    }

    let totalTransactions = try dbQueue.read { database in
        try Transaction.fetchCount(database)
    }

    #expect(transactionsWithLedgerId == totalTransactions)
}

@Test
func ledgerMigrationPreservesAccountProperties() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
        try DatabaseSeeder.seedAccounts(in: database)
    }

    let originalAccounts = try dbQueue.read { database in
        try Account.fetchAll(database)
    }

    let ledgers = try dbQueue.read { database in
        try Ledger
            .filter(Ledger.Columns.kind == LedgerKind.bankAccount.rawValue)
            .fetchAll(database)
    }

    #expect(ledgers.count == originalAccounts.count)

    for original in originalAccounts {
        let ledger = ledgers.first { $0.id == original.id }
        #expect(ledger != nil)
        #expect(ledger?.bankId == original.bankId)
        #expect(ledger?.displayName == original.accountName)
        #expect(ledger?.accountType == original.accountType)
        #expect(ledger?.kind == .bankAccount)
    }
}

@Test
func ledgerMigrationPreservesCardProperties() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
        try DatabaseSeeder.seedAccounts(in: database)
        try DatabaseSeeder.seedCards(in: database)
    }

    let originalCards = try dbQueue.read { database in
        try Card.fetchAll(database)
    }

    let ledgers = try dbQueue.read { database in
        try Ledger
            .filter(Ledger.Columns.kind == LedgerKind.creditCard.rawValue)
            .fetchAll(database)
    }

    #expect(ledgers.count == originalCards.count)

    for original in originalCards {
        let ledger = ledgers.first { $0.id == original.id }
        #expect(ledger != nil)
        #expect(ledger?.bankId == original.bankId)
        #expect(ledger?.displayName == original.cardName)
        #expect(ledger?.cardType == original.cardType)
        #expect(ledger?.linkedLedgerId == original.linkedAccountId)
        #expect(ledger?.kind == .creditCard)
    }
}
