@testable import FinanceCore
import Foundation
import GRDB
import Testing

// MARK: - Helpers

private func makeDedupDB() async throws -> (DatabaseQueue, GRDBTransactionRepository) {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)
    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)
    try await dbQueue.write { database in try DatabaseSeeder.seedBanks(in: database) }
    return (dbQueue, GRDBTransactionRepository(dbQueue: dbQueue))
}

private func insertLedger(_ dbQueue: DatabaseQueue, bankId: UUID, kind: LedgerKind) async throws -> Ledger {
    let ledger = Ledger(bankId: bankId, kind: kind, displayName: "Ledger \(kind.rawValue)")
    try await dbQueue.write { database in try ledger.insert(database) }
    return ledger
}

private func makeTxn(ledgerId: UUID, accountID: UUID?, fingerprint: String) -> Transaction {
    Transaction(
        ledgerId: ledgerId,
        accountID: accountID,
        cardID: accountID == nil ? ledgerId : nil,
        postedAt: Date(timeIntervalSince1970: 0),
        description: "txn",
        amountMinorUnits: 1000,
        currencyCode: "INR",
        transactionType: .debit,
        sourceFingerprint: fingerprint
    )
}

// MARK: - Tests

@Test
func reImportingSameTransactionsProducesSkipped() async throws {
    let (dbQueue, repo) = try await makeDedupDB()
    let bank = try await #require(dbQueue.read { database in try Bank.fetchAll(database).first })
    let ledger = try await insertLedger(dbQueue, bankId: bank.id, kind: .bankAccount)

    let txn = makeTxn(ledgerId: ledger.id, accountID: ledger.id, fingerprint: "test|20260501|10000")

    let first = try await repo.insertTransactions([txn])
    #expect(first.inserted == 1)
    #expect(first.skipped == 0)

    let second = try await repo.insertTransactions([txn])
    #expect(second.inserted == 0)
    #expect(second.skipped == 1)
}

@Test
func sameFingerprintDifferentLedgers_bothAllowed() async throws {
    let (dbQueue, repo) = try await makeDedupDB()
    let bank = try await #require(dbQueue.read { database in try Bank.fetchAll(database).first })
    let ledger1 = try await insertLedger(dbQueue, bankId: bank.id, kind: .bankAccount)
    let ledger2 = try await insertLedger(dbQueue, bankId: bank.id, kind: .bankAccount)

    let fingerprint = "shared-fingerprint-001"
    let txn1 = makeTxn(ledgerId: ledger1.id, accountID: ledger1.id, fingerprint: fingerprint)
    let txn2 = makeTxn(ledgerId: ledger2.id, accountID: ledger2.id, fingerprint: fingerprint)

    let result1 = try await repo.insertTransactions([txn1])
    #expect(result1.inserted == 1)
    #expect(result1.skipped == 0)

    let result2 = try await repo.insertTransactions([txn2])
    #expect(result2.inserted == 1, "Same fingerprint in different ledger must be allowed")
    #expect(result2.skipped == 0)
}

@Test
func duplicateRowsInSameFile_onlyOneInserted() async throws {
    let (dbQueue, repo) = try await makeDedupDB()
    let bank = try await #require(dbQueue.read { database in try Bank.fetchAll(database).first })
    let ledger = try await insertLedger(dbQueue, bankId: bank.id, kind: .bankAccount)

    let fingerprint = "dup-in-file-001"
    let txn = makeTxn(ledgerId: ledger.id, accountID: ledger.id, fingerprint: fingerprint)

    let result = try await repo.insertTransactions([txn, txn])
    #expect(result.inserted == 1)
    #expect(result.skipped == 1)
}

@Test
func sameLedgerReimport_skipped() async throws {
    let (dbQueue, repo) = try await makeDedupDB()
    let bank = try await #require(dbQueue.read { database in try Bank.fetchAll(database).first })
    let ledger = try await insertLedger(dbQueue, bankId: bank.id, kind: .bankAccount)

    let txns = (1 ... 3).map { index in
        makeTxn(ledgerId: ledger.id, accountID: ledger.id, fingerprint: "fp-\(index)")
    }

    let first = try await repo.insertTransactions(txns)
    #expect(first.inserted == 3)

    let second = try await repo.insertTransactions(txns)
    #expect(second.inserted == 0)
    #expect(second.skipped == 3)
}

@Test
func sameDateAmountDescDifferentFingerprint_bothInserted() async throws {
    let (dbQueue, repo) = try await makeDedupDB()
    let bank = try await #require(dbQueue.read { database in try Bank.fetchAll(database).first })
    let ledger = try await insertLedger(dbQueue, bankId: bank.id, kind: .bankAccount)

    let txn1 = Transaction(
        ledgerId: ledger.id,
        accountID: ledger.id,
        cardID: nil,
        postedAt: Date(timeIntervalSince1970: 0),
        description: "Coffee",
        amountMinorUnits: 500,
        currencyCode: "INR",
        transactionType: .debit,
        sourceFingerprint: "fp-source-a"
    )
    let txn2 = Transaction(
        ledgerId: ledger.id,
        accountID: ledger.id,
        cardID: nil,
        postedAt: Date(timeIntervalSince1970: 0),
        description: "Coffee",
        amountMinorUnits: 500,
        currencyCode: "INR",
        transactionType: .debit,
        sourceFingerprint: "fp-source-b"
    )

    let result = try await repo.insertTransactions([txn1, txn2])
    #expect(result.inserted == 2, "Different fingerprints must both be inserted even if date/amount/desc match")
    #expect(result.skipped == 0)
}
