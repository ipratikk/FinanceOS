@testable import FinanceCore
import GRDB
import Testing

@Test
func reImportingSameTransactionsProducesSkipped() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedInstitutions(in: database)
        try DatabaseSeeder.seedBanks(in: database)
        try DatabaseSeeder.seedAccounts(in: database)
        try DatabaseSeeder.seedCards(in: database)
    }

    let repo = GRDBTransactionRepository(dbQueue: dbQueue)

    let accountID = try dbQueue.read { database in
        try Account.fetchAll(database).first!.id
    }

    let txn = Transaction(
        accountID: accountID,
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
        try DatabaseSeeder.seedInstitutions(in: database)
        try DatabaseSeeder.seedBanks(in: database)
        try DatabaseSeeder.seedAccounts(in: database)
    }

    let repo = GRDBTransactionRepository(dbQueue: dbQueue)

    let accounts = try dbQueue.read { database in
        try Account.fetchAll(database)
    }

    guard accounts.count >= 2 else {
        fatalError("Need at least 2 accounts for this test")
    }

    let fingerprint = "test|20260501|10000"
    let txn1 = Transaction(
        accountID: accounts[0].id,
        postedAt: Date(timeIntervalSince1970: 0),
        description: "Test Transaction",
        amountMinorUnits: 10000,
        currencyCode: "INR",
        transactionType: .debit,
        sourceFingerprint: fingerprint
    )

    let txn2 = Transaction(
        accountID: accounts[1].id,
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
            result = .success(try await body())
        } catch {
            result = .failure(error)
        }
        semaphore.signal()
    }

    semaphore.wait()
    return try result!.get()
}
