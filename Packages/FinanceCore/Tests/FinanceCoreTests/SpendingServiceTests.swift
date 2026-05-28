@testable import FinanceCore
import FinanceParsers
import Foundation
import GRDB
import Testing

// MARK: - Helpers

private func makeSpendingDB() throws -> (DatabaseQueue, GRDBSpendingService) {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)
    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)
    try dbQueue.write { database in try DatabaseSeeder.seedBanks(in: database) }
    let txnRepo = GRDBTransactionRepository(dbQueue: dbQueue)
    let ledgerRepo = GRDBLedgerRepository(dbQueue: dbQueue)
    let service = GRDBSpendingService(dbQueue: dbQueue, transactionRepository: txnRepo, ledgerRepository: ledgerRepo)
    return (dbQueue, service)
}

private func insertLedger(bankId: UUID, kind: LedgerKind, in dbQueue: DatabaseQueue) throws -> Ledger {
    let ledger = Ledger(bankId: bankId, kind: kind, displayName: "\(kind.rawValue) Ledger")
    try dbQueue.write { database in try ledger.insert(database) }
    return ledger
}

// signedAmount: positive = debit, negative = credit
private func insertTransaction(
    ledgerId: UUID,
    date: Date,
    signedAmount: Int64,
    fingerprint: String,
    dbQueue: DatabaseQueue
) throws {
    let txnType: TransactionType = signedAmount >= 0 ? .debit : .credit
    let txn = Transaction(
        ledgerId: ledgerId,
        accountID: ledgerId,
        cardID: nil,
        postedAt: date,
        description: "txn-\(fingerprint)",
        amountMinorUnits: abs(signedAmount),
        currencyCode: "INR",
        transactionType: txnType,
        sourceFingerprint: fingerprint
    )
    try dbQueue.write { database in try txn.insert(database) }
}

private func currentMonthDate(dayOffset: Int = 0) -> Date {
    let calendar = Calendar.current
    let comps = calendar.dateComponents([.year, .month], from: Date())
    var base = calendar.date(from: comps) ?? Date()
    base = calendar.date(byAdding: .day, value: dayOffset, to: base) ?? Date()
    return base
}

// MARK: - Tests

@Test
func spendingService_debitTransactionCountsAsDebit() async throws {
    let (dbQueue, service) = try makeSpendingDB()
    let bank = try await #require(dbQueue.read { database in try Bank.fetchAll(database).first })
    let ledger = try insertLedger(bankId: bank.id, kind: .bankAccount, in: dbQueue)

    try insertTransaction(
        ledgerId: ledger.id,
        date: currentMonthDate(), signedAmount: 10000,
        fingerprint: "debit-only-001", dbQueue: dbQueue
    )

    let totals = try await service.currentMonthTotals()
    #expect(totals.totalDebit == 10000)
    #expect(totals.totalCredit == 0)
    #expect(totals.transactionCount == 1)
}

@Test
func spendingService_creditTransactionCountsAsCredit() async throws {
    let (dbQueue, service) = try makeSpendingDB()
    let bank = try await #require(dbQueue.read { database in try Bank.fetchAll(database).first })
    let ledger = try insertLedger(bankId: bank.id, kind: .bankAccount, in: dbQueue)

    try insertTransaction(
        ledgerId: ledger.id,
        date: currentMonthDate(), signedAmount: -50000,
        fingerprint: "credit-only-001", dbQueue: dbQueue
    )

    let totals = try await service.currentMonthTotals()
    #expect(totals.totalDebit == 0)
    #expect(totals.totalCredit == 50000)
    #expect(totals.transactionCount == 1)
}

@Test
func spendingService_refundImportClassifiedAsCredit() async throws {
    let (dbQueue, service) = try makeSpendingDB()
    let bank = try await #require(dbQueue.read { database in try Bank.fetchAll(database).first })
    let ledger = try insertLedger(bankId: bank.id, kind: .bankAccount, in: dbQueue)

    // Simulate parsed refund: negative amountMinorUnits → mapper sets type=.credit, absolute amount
    let parsedRefund = ParsedTransaction(
        postedAt: currentMonthDate(),
        description: "Refund - Amazon",
        amountMinorUnits: -5000,
        currencyCode: "INR",
        sourceFingerprint: "refund-001"
    )
    let mapped = ParsedTransactionMapper.map(
        parsedRefund,
        target: .ledger(ledger.id),
        ledgerKind: .bankAccount
    )
    #expect(mapped.transactionType == TransactionType.credit)
    #expect(mapped.amountMinorUnits == 5000)

    try await dbQueue.write { database in try mapped.insert(database) }

    let totals = try await service.currentMonthTotals()
    #expect(totals.totalCredit == 5000)
    #expect(totals.totalDebit == 0)
}

@Test
func spendingService_mixedMonthlyDebitsAndCredits() async throws {
    let (dbQueue, service) = try makeSpendingDB()
    let bank = try await #require(dbQueue.read { database in try Bank.fetchAll(database).first })
    let ledger = try insertLedger(bankId: bank.id, kind: .bankAccount, in: dbQueue)

    // 3 debits
    try insertTransaction(
        ledgerId: ledger.id,
        date: currentMonthDate(), signedAmount: 1000, fingerprint: "m-d1", dbQueue: dbQueue
    )
    try insertTransaction(
        ledgerId: ledger.id,
        date: currentMonthDate(), signedAmount: 2000, fingerprint: "m-d2", dbQueue: dbQueue
    )
    try insertTransaction(
        ledgerId: ledger.id,
        date: currentMonthDate(), signedAmount: 3000, fingerprint: "m-d3", dbQueue: dbQueue
    )
    // 2 credits
    try insertTransaction(
        ledgerId: ledger.id,
        date: currentMonthDate(), signedAmount: -10000, fingerprint: "m-c1", dbQueue: dbQueue
    )
    try insertTransaction(
        ledgerId: ledger.id,
        date: currentMonthDate(), signedAmount: -5000, fingerprint: "m-c2", dbQueue: dbQueue
    )

    let totals = try await service.currentMonthTotals()
    #expect(totals.totalDebit == 6000)
    #expect(totals.totalCredit == 15000)
    #expect(totals.transactionCount == 5)
}

@Test
func spendingService_monthlySummaryGroupsCorrectly() async throws {
    let (dbQueue, service) = try makeSpendingDB()
    let bank = try await #require(dbQueue.read { database in try Bank.fetchAll(database).first })
    let ledger = try insertLedger(bankId: bank.id, kind: .bankAccount, in: dbQueue)

    let thisMonth = currentMonthDate()
    // Last month
    let lastMonthStart = Calendar.current.date(byAdding: .month, value: -1, to: thisMonth) ?? Date()

    try insertTransaction(
        ledgerId: ledger.id,
        date: thisMonth, signedAmount: 8000, fingerprint: "ms-curr-d", dbQueue: dbQueue
    )
    try insertTransaction(
        ledgerId: ledger.id,
        date: lastMonthStart, signedAmount: -3000, fingerprint: "ms-prev-c", dbQueue: dbQueue
    )

    let summary = try await service.monthlySummary(months: 12)
    #expect(summary.count == 2)

    let thisMonthSummary = try #require(summary.first {
        Calendar.current.isDate($0.month, equalTo: thisMonth, toGranularity: .month)
    })
    #expect(thisMonthSummary.totalDebit == 8000)
    #expect(thisMonthSummary.totalCredit == 0)

    let lastMonthSummary = try #require(summary.first {
        Calendar.current.isDate($0.month, equalTo: lastMonthStart, toGranularity: .month)
    })
    #expect(lastMonthSummary.totalDebit == 0)
    #expect(lastMonthSummary.totalCredit == 3000)
}

@Test
func spendingService_excludesPreviousMonthFromCurrentTotals() async throws {
    let (dbQueue, service) = try makeSpendingDB()
    let bank = try await #require(dbQueue.read { database in try Bank.fetchAll(database).first })
    let ledger = try insertLedger(bankId: bank.id, kind: .bankAccount, in: dbQueue)

    let thisMonth = currentMonthDate()
    let lastMonthStart = Calendar.current.date(byAdding: .month, value: -1, to: thisMonth) ?? Date()

    try insertTransaction(
        ledgerId: ledger.id,
        date: thisMonth, signedAmount: 1000, fingerprint: "curr-only", dbQueue: dbQueue
    )
    try insertTransaction(
        ledgerId: ledger.id,
        date: lastMonthStart, signedAmount: 99999, fingerprint: "prev-excluded", dbQueue: dbQueue
    )

    let totals = try await service.currentMonthTotals()
    #expect(totals.totalDebit == 1000)
    #expect(totals.transactionCount == 1)
}
