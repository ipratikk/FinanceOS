@testable import FinanceCore
import Dispatch
import Foundation
import GRDB
import Testing

@Test
func reImportingSameTransactionsProducesSkipped() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let repo = GRDBTransactionRepository(dbQueue: dbQueue)

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
        description: "Test Transaction",
        amountMinorUnits: 10000,
        currencyCode: "INR",
        transactionType: .debit,
        sourceFingerprint: "test|20260501|10000"
    )

    let firstImport = try awaitThrows {
        await repo.insertTransactions([txn])
    }
    #expect(firstImport.inserted == 1)
    #expect(firstImport.skipped == 0)

    let secondImport = try awaitThrows {
        await repo.insertTransactions([txn])
    }
    #expect(secondImport.inserted == 0)
    #expect(secondImport.skipped == 1)
}

@Test
func sameFingerprointDifferentAccountsInsertBoth() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let repo = GRDBTransactionRepository(dbQueue: dbQueue)

    let bank = try dbQueue.read { database in
        try Bank.fetchAll(database).first!
    }

    let ledger1 = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Account 1"
    )

    let ledger2 = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Account 2"
    )

    try dbQueue.write { database in
        try ledger1.insert(database)
        try ledger2.insert(database)
    }

    let fingerprint = "test|20260501|10000"

    let txn1 = Transaction(
        ledgerId: ledger1.id,
        accountID: ledger1.id,
        postedAt: Date(timeIntervalSince1970: 0),
        description: "Test Transaction",
        amountMinorUnits: 10000,
        currencyCode: "INR",
        transactionType: .debit,
        sourceFingerprint: fingerprint
    )

    let txn2 = Transaction(
        ledgerId: ledger2.id,
        accountID: ledger2.id,
        postedAt: Date(timeIntervalSince1970: 0),
        description: "Test Transaction",
        amountMinorUnits: 10000,
        currencyCode: "INR",
        transactionType: .debit,
        sourceFingerprint: fingerprint
    )

    let result1 = try awaitThrows {
        await repo.insertTransactions([txn1])
    }
    #expect(result1.inserted == 1)

    let result2 = try awaitThrows {
        await repo.insertTransactions([txn2])
    }
    #expect(result2.inserted == 1)
    #expect(result2.skipped == 0)

    let allTransactions = try dbQueue.read { database in
        try Transaction.fetchAll(database)
    }
    #expect(allTransactions.count == 2)
}

private func awaitThrows<T>(_ body: @escaping () async throws -> T) throws -> T {
    var result: Result<T, Error>?
    let semaphore = DispatchSemaphore(value: 0)

    Task {
        do {
            result = try await .success(body())
        } catch {
            result = .failure(error)
        }
        semaphore.signal()
    }

    semaphore.wait()
    return try result!.get()
}
