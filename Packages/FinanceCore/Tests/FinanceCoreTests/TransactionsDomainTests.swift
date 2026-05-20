@testable import FinanceCore
import Foundation
import GRDB
import Testing

@Test
func transactionsCanBeInsertedAgainstLedger() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(
        in: &migrator
    )

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
        displayName: "HDFC Savings"
    )

    let cardLedger = Ledger(
        bankId: bank.id,
        kind: .creditCard,
        displayName: "HDFC Regalia"
    )

    try dbQueue.write { database in
        try accountLedger.insert(database)
        try cardLedger.insert(database)
    }

    try dbQueue.write { database in
        let accountTxn = Transaction(
            ledgerId: accountLedger.id,
            accountID: accountLedger.id,
            postedAt: Date(timeIntervalSince1970: 0),
            description: "Grocery Store",
            amountMinorUnits: 50000,
            currencyCode: "INR",
            transactionType: .debit
        )
        let cardTxn = Transaction(
            ledgerId: cardLedger.id,
            cardID: cardLedger.id,
            postedAt: Date(timeIntervalSince1970: 1000),
            description: "Restaurant",
            amountMinorUnits: 20000,
            currencyCode: "INR",
            transactionType: .debit
        )
        let creditTxn = Transaction(
            ledgerId: accountLedger.id,
            accountID: accountLedger.id,
            postedAt: Date(timeIntervalSince1970: 2000),
            description: "Salary Credit",
            amountMinorUnits: 500_000,
            currencyCode: "INR",
            transactionType: .credit
        )
        try accountTxn.insert(database)
        try cardTxn.insert(database)
        try creditTxn.insert(database)
    }

    let transactions = try dbQueue.read { database in
        try Transaction.fetchAll(database)
    }

    #expect(transactions.count == 3)
    #expect(transactions.contains { $0.ledgerId == accountLedger.id })
    #expect(transactions.contains { $0.ledgerId == cardLedger.id })
}

@Test
func transactionInsertionIsIdempotentViaFingerprint() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(
        in: &migrator
    )

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let bank = try dbQueue.read { database in
        try Bank.fetchAll(database).first!
    }

    let ledger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Test Account"
    )

    try dbQueue.write { database in
        try ledger.insert(database)
    }

    let txn = Transaction(
        ledgerId: ledger.id,
        accountID: ledger.id,
        postedAt: Date(timeIntervalSince1970: 0),
        description: "Test",
        amountMinorUnits: 10000,
        currencyCode: "INR",
        transactionType: .debit,
        sourceFingerprint: "unique-fp-001"
    )

    try dbQueue.write { database in
        try txn.insert(database)
    }

    var countAfterFirst = try dbQueue.read { database in
        try Transaction.fetchCount(database)
    }
    #expect(countAfterFirst == 1)

    // Inserting the same row again should fail the unique index — count stays 1
    try dbQueue.write { database in
        do {
            try txn.insert(database)
        } catch let error as DatabaseError where error.resultCode == .SQLITE_CONSTRAINT {
            // Expected: fingerprint uniqueness enforced
        }
    }

    countAfterFirst = try dbQueue.read { database in
        try Transaction.fetchCount(database)
    }
    #expect(countAfterFirst == 1)
}
