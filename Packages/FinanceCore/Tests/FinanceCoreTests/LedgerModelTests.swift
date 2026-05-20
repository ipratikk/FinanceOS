@testable import FinanceCore
import Foundation
import GRDB
import Testing

@Test
func ledgerKindDisplayNames() {
    #expect(LedgerKind.bankAccount.displayName == "Bank Account")
    #expect(LedgerKind.creditCard.displayName == "Credit Card")
    #expect(LedgerKind.loan.displayName == "Loan")
    #expect(LedgerKind.wallet.displayName == "Wallet")
    #expect(LedgerKind.crypto.displayName == "Crypto")
    #expect(LedgerKind.investment.displayName == "Investment")
}

@Test
func ledgerKindCodable() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let kind = LedgerKind.creditCard
    let encoded = try encoder.encode(kind)
    let decoded = try decoder.decode(LedgerKind.self, from: encoded)

    #expect(decoded == kind)
}

@Test
func ledgerGRDBRoundTrip() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let banks = try await dbQueue.read { database in
        try Bank.fetchAll(database)
    }

    guard let bank = banks.first else {
        fatalError("No banks seeded")
    }

    let bankAccountLedger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Savings Account",
        last4: "1234",
        ownerName: "Test User",
        accountType: "savings"
    )

    let cardLedger = Ledger(
        bankId: bank.id,
        kind: .creditCard,
        displayName: "Credit Card",
        last4: "5678",
        cardType: .visa,
        cardProductId: "regalia",
        linkedLedgerId: bankAccountLedger.id
    )

    try await dbQueue.write { database in
        try bankAccountLedger.insert(database)
        try cardLedger.insert(database)
    }

    let fetchedLedgers = try await dbQueue.read { database in
        try Ledger.fetchAll(database)
    }

    #expect(fetchedLedgers.count == 2)
    #expect(fetchedLedgers.contains(where: { $0.id == bankAccountLedger.id }))
    #expect(fetchedLedgers.contains(where: { $0.id == cardLedger.id }))
}

@Test
func ledgerFilterByKind() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let bank = try await dbQueue.read { database in
        try Bank.fetchAll(database).first!
    }

    let account = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Account",
        accountType: "savings"
    )

    let card = Ledger(
        bankId: bank.id,
        kind: .creditCard,
        displayName: "Card",
        cardType: .visa
    )

    try await dbQueue.write { database in
        try account.insert(database)
        try card.insert(database)
    }

    let accounts = try await dbQueue.read { database in
        try Ledger
            .filter(Ledger.Columns.kind == LedgerKind.bankAccount.rawValue)
            .fetchAll(database)
    }

    let cards = try await dbQueue.read { database in
        try Ledger
            .filter(Ledger.Columns.kind == LedgerKind.creditCard.rawValue)
            .fetchAll(database)
    }

    #expect(accounts.count == 1)
    #expect(accounts[0].kind == .bankAccount)
    #expect(cards.count == 1)
    #expect(cards[0].kind == .creditCard)
}

@Test
func ledgerFilterByBankAndKind() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let banks = try await dbQueue.read { database in
        try Bank.fetchAll(database)
    }

    guard banks.count >= 2 else {
        fatalError("Need at least 2 banks")
    }

    let hdfcBank = try #require(banks.first(where: { $0.name == "HDFC" }))
    let iciciBank = try #require(banks.first(where: { $0.name == "ICICI" }))

    let hdfcAccount = Ledger(
        bankId: hdfcBank.id,
        kind: .bankAccount,
        displayName: "HDFC Account"
    )

    let hdfcCard = Ledger(
        bankId: hdfcBank.id,
        kind: .creditCard,
        displayName: "HDFC Card"
    )

    let iciciCard = Ledger(
        bankId: iciciBank.id,
        kind: .creditCard,
        displayName: "ICICI Card"
    )

    try await dbQueue.write { database in
        try hdfcAccount.insert(database)
        try hdfcCard.insert(database)
        try iciciCard.insert(database)
    }

    let hdfcCards = try await dbQueue.read { database in
        try Ledger
            .filter(Ledger.Columns.bankId == hdfcBank.id)
            .filter(Ledger.Columns.kind == LedgerKind.creditCard.rawValue)
            .fetchAll(database)
    }

    #expect(hdfcCards.count == 1)
    #expect(hdfcCards[0].id == hdfcCard.id)
}

@Test
func ledgerLinkedRelationship() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

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
        displayName: "Card",
        linkedLedgerId: account.id
    )

    try await dbQueue.write { database in
        try account.insert(database)
        try card.insert(database)
    }

    let fetchedCard = try await dbQueue.read { database in
        try Ledger.fetchOne(database, id: card.id)
    }

    #expect(fetchedCard?.linkedLedgerId == account.id)
}

@Test
func ledgerArchiveFlag() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let bank = try await dbQueue.read { database in
        try Bank.fetchAll(database).first!
    }

    let ledger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Account"
    )

    try await dbQueue.write { database in
        try ledger.insert(database)
    }

    let activeLedgers = try await dbQueue.read { database in
        try Ledger
            .filter(Ledger.Columns.isArchived == false)
            .fetchAll(database)
    }

    #expect(activeLedgers.count == 1)

    let archived = Ledger(
        id: ledger.id,
        bankId: ledger.bankId,
        kind: ledger.kind,
        displayName: ledger.displayName,
        last4: ledger.last4,
        nickname: ledger.nickname,
        ownerName: ledger.ownerName,
        createdAt: ledger.createdAt,
        accountType: ledger.accountType,
        cardType: ledger.cardType,
        cardProductId: ledger.cardProductId,
        bin: ledger.bin,
        linkedLedgerId: ledger.linkedLedgerId,
        isArchived: true
    )

    try await dbQueue.write { database in
        try archived.update(database)
    }

    let stillActive = try await dbQueue.read { database in
        try Ledger
            .filter(Ledger.Columns.isArchived == false)
            .fetchAll(database)
    }

    #expect(stillActive.count == 0)
}
