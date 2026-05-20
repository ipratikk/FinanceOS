@testable import FinanceCore
import FinanceParsers
import Foundation
import GRDB
import Testing

@Test
func importFlowE2E_successfulAccountImport() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let bankRepository = GRDBBankRepository(dbQueue: dbQueue)
    let ledgerRepository = GRDBLedgerRepository(dbQueue: dbQueue)
    let transactionRepository = GRDBTransactionRepository(dbQueue: dbQueue)

    let bank = try await #require(bankRepository.fetchBanks().first)

    let ledger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Test Account"
    )

    try await ledgerRepository.insert(ledger)

    let statement = ParsedStatement(
        bankName: bank.name,
        accountName: "Test Account",
        accountLast4: "1234",
        cardLast4: nil,
        transactions: [
            ParsedTransaction(
                postedAt: Date(),
                description: "Test Transaction",
                amountMinorUnits: 50000,
                currencyCode: "INR",
                sourceFingerprint: "test|1|50000"
            )
        ],
        metadata: nil
    )

    let target = TransactionImportTarget.ledger(ledger.id)
    let pipeline = TransactionImportPipeline(repository: transactionRepository)
    let context = OperationContext.importSession()
    let result = try await pipeline.execute(
        statement: statement,
        target: target,
        ledgerKind: ledger.kind,
        context: context
    )

    #expect(result.inserted == 1)
    #expect(result.skipped == 0)

    let importedTxns = try await transactionRepository.fetchTransactions()
    #expect(importedTxns.count == 1)
    #expect(importedTxns[0].ledgerId == ledger.id)
    #expect(importedTxns[0].description == "Test Transaction")
    #expect(importedTxns[0].transactionType == .debit)
    #expect(importedTxns[0].amountMinorUnits == 50000)
}

@Test
func importFlowE2E_deduplicationWorksWithLedgerId() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let bankRepository = GRDBBankRepository(dbQueue: dbQueue)
    let ledgerRepository = GRDBLedgerRepository(dbQueue: dbQueue)
    let transactionRepository = GRDBTransactionRepository(dbQueue: dbQueue)

    let bank = try await #require(bankRepository.fetchBanks().first)
    let ledger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Test Account"
    )
    try await ledgerRepository.insert(ledger)

    let txn = ParsedTransaction(
        postedAt: Date(),
        description: "Duplicate Test",
        amountMinorUnits: 10000,
        currencyCode: "INR",
        sourceFingerprint: "dup|test|10000"
    )

    let statement = ParsedStatement(
        bankName: bank.name,
        accountName: "Test Account",
        accountLast4: "1234",
        cardLast4: nil,
        transactions: [txn, txn],
        metadata: nil
    )

    let target = TransactionImportTarget.ledger(ledger.id)
    let pipeline = TransactionImportPipeline(repository: transactionRepository)
    let context = OperationContext.importSession()
    let result = try await pipeline.execute(
        statement: statement,
        target: target,
        ledgerKind: ledger.kind,
        context: context
    )

    #expect(result.inserted == 1)
    #expect(result.skipped == 1)

    let allTxns = try await transactionRepository.fetchTransactions()
    #expect(allTxns.count == 1)
}

@Test
func importFlowE2E_targetMatchingFindsLedgerByLast4() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let bankRepository = GRDBBankRepository(dbQueue: dbQueue)
    let ledgerRepository = GRDBLedgerRepository(dbQueue: dbQueue)

    let bank = try await #require(bankRepository.fetchBanks().first)

    let ledger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Account 1234",
        last4: "1234"
    )
    try await ledgerRepository.insert(ledger)

    let statement = ParsedStatement(
        bankName: bank.name,
        accountName: "Account",
        accountLast4: "1234",
        cardLast4: nil,
        transactions: [],
        metadata: nil
    )

    let allLedgers = try await ledgerRepository.fetchLedgers()
    let matchedTarget = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: allLedgers,
        banks: [bank]
    )

    #expect(matchedTarget == .ledger(ledger.id))
}

@Test
func importFlowE2E_creditCardImport() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let bankRepository = GRDBBankRepository(dbQueue: dbQueue)
    let ledgerRepository = GRDBLedgerRepository(dbQueue: dbQueue)
    let transactionRepository = GRDBTransactionRepository(dbQueue: dbQueue)

    let bank = try await #require(bankRepository.fetchBanks().first)

    let card = Ledger(
        bankId: bank.id,
        kind: .creditCard,
        displayName: "Test Card",
        last4: "5678"
    )
    try await ledgerRepository.insert(card)

    let statement = ParsedStatement(
        bankName: bank.name,
        accountName: "Test Card",
        accountLast4: nil,
        cardLast4: "5678",
        transactions: [
            ParsedTransaction(
                postedAt: Date(),
                description: "Card Purchase",
                amountMinorUnits: 25000,
                currencyCode: "INR",
                sourceFingerprint: "card|purchase|25000"
            )
        ],
        metadata: nil
    )

    let target = TransactionImportTarget.ledger(card.id)
    let pipeline = TransactionImportPipeline(repository: transactionRepository)
    let context = OperationContext.importSession()
    let result = try await pipeline.execute(
        statement: statement,
        target: target,
        ledgerKind: card.kind,
        context: context
    )

    #expect(result.inserted == 1)

    let txns = try await transactionRepository.fetchTransactions()
    #expect(txns.count == 1)
    #expect(txns[0].ledgerId == card.id)
    #expect(txns[0].description == "Card Purchase")
}

@Test
func importFlowE2E_archiveBlocksDeletion() async throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)

    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)

    try await dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
    }

    let bankRepository = GRDBBankRepository(dbQueue: dbQueue)
    let ledgerRepository = GRDBLedgerRepository(dbQueue: dbQueue)
    let transactionRepository = GRDBTransactionRepository(dbQueue: dbQueue)

    let bank = try await #require(bankRepository.fetchBanks().first)
    let ledger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: "Test Account"
    )
    try await ledgerRepository.insert(ledger)

    let statement = ParsedStatement(
        bankName: bank.name,
        accountName: "Test Account",
        accountLast4: nil,
        cardLast4: nil,
        transactions: [
            ParsedTransaction(
                postedAt: Date(),
                description: "Test",
                amountMinorUnits: 10000,
                currencyCode: "INR",
                sourceFingerprint: "test"
            )
        ],
        metadata: nil
    )

    let target = TransactionImportTarget.ledger(ledger.id)
    let pipeline = TransactionImportPipeline(repository: transactionRepository)
    let context = OperationContext.importSession()
    _ = try await pipeline.execute(statement: statement, target: target, ledgerKind: ledger.kind, context: context)

    try await ledgerRepository.archive(id: ledger.id)

    var deletionError: RepositoryError?
    do {
        try await ledgerRepository.delete(id: ledger.id)
    } catch let error as RepositoryError {
        deletionError = error
    }

    #expect(deletionError != nil)
    if case .deleteFailed = try #require(deletionError) {
        // Expected - cannot delete ledger with transactions
    } else {
        fatalError("Wrong error type")
    }
}
