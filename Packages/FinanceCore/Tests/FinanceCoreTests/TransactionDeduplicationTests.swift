@testable import FinanceCore
import Foundation
import GRDB
import Testing

@Test
func reImportingSameTransactionsProducesSkipped() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let repo = GRDBTransactionRepository(dbQueue: dbQueue)

    let bank = try #require(await dbQueue.read { database in
        try Bank.fetchAll(database).first
    })

    let ledger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Test Account"
    )

    try await dbQueue.write { database in
        try ledger.insert(database)
    }

    let txn = Transaction(
        ledgerId: ledger.id,
        accountID: ledger.id,
        postedAt: Date(timeIntervalSince1970: 0),
        description: "Test Transaction",
        amountMinorUnits: 10000,
        currencyCode: "INR",
        transactionType: .debit,
        sourceFingerprint: "test|20260501|10000"
    )

    let firstImport = try await repo.insertTransactions([txn])
    #expect(firstImport.inserted == 1)
    #expect(firstImport.skipped == 0)

    let secondImport = try await repo.insertTransactions([txn])
    #expect(secondImport.inserted == 0)
    #expect(secondImport.skipped == 1)
}
