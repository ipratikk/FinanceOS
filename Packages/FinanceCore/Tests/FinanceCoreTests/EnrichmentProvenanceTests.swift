@testable import FinanceCore
import Foundation
import GRDB
import Testing

// MARK: - Helpers

private func makeDB() throws -> DatabaseQueue {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)
    let db = try DatabaseQueue()
    try migrator.migrate(db)
    try db.write { try DatabaseSeeder.seedBanks(in: $0) }
    return db
}

private func makeTransaction(ledgerId: UUID) -> Transaction {
    Transaction(
        ledgerId: ledgerId,
        postedAt: Date(),
        description: "UPI-ZEPTO-zepto@hdfc",
        amountMinorUnits: 50000,
        currencyCode: "INR"
    )
}

private func insertLedgerAndTransaction(in db: DatabaseQueue) async throws -> (ledgerId: UUID, txnId: UUID) {
    let bank = try await db.read { try Bank.fetchAll($0).first! }
    let ledger = Ledger(bankId: bank.id, kind: .bankAccount, displayName: "Test")
    let repo = GRDBLedgerRepository(dbQueue: db)
    try await repo.insert(ledger)

    let txn = makeTransaction(ledgerId: ledger.id)
    let txnRepo = GRDBTransactionRepository(dbQueue: db)
    _ = try await txnRepo.insertTransactions([txn])
    return (ledger.id, txn.id)
}

// MARK: - v23 migration: new provenance columns exist

@Test
func v23MigrationAddsProvenanceColumns() async throws {
    let db = try makeDB()
    let cols = try await db.read { try $0.columns(in: "transactions").map(\.name) }
    #expect(cols.contains("lastEnrichedAt"))
    #expect(cols.contains("intelligenceSource"))
    #expect(cols.contains("intelligenceModelVersion"))
    #expect(cols.contains("intelligenceConfigVersion"))
    #expect(cols.contains("isUserCorrectedMerchant"))
}

// MARK: - updateEnrichmentProvenance writes all provenance fields

@Test
func updateEnrichmentProvenanceWritesAllFields() async throws {
    let db = try makeDB()
    let (_, txnId) = try await insertLedgerAndTransaction(in: db)
    let repo = GRDBTransactionRepository(dbQueue: db)
    let enrichedAt = Date()

    try await repo.updateEnrichmentProvenance(
        id: txnId,
        EnrichmentProvenance(
            categoryId: "food",
            merchantName: "Zepto",
            intentId: "shopping",
            resolvedPersonId: nil,
            lastEnrichedAt: enrichedAt,
            intelligenceSource: "structuralRule",
            intelligenceModelVersion: "rule-v1",
            intelligenceConfigVersion: "2026-06-01.v1"
        )
    )

    let fetched = try await db.read { db in
        try Transaction.filter(Transaction.Columns.id == txnId).fetchOne(db)
    }
    #expect(fetched?.categoryId == "food")
    #expect(fetched?.merchantName == "Zepto")
    #expect(fetched?.intentId == "shopping")
    #expect(fetched?.intelligenceSource == "structuralRule")
    #expect(fetched?.intelligenceModelVersion == "rule-v1")
    #expect(fetched?.intelligenceConfigVersion == "2026-06-01.v1")
    #expect(fetched?.lastEnrichedAt != nil)
}

// MARK: - isUserCorrectedMerchant protects merchant from intelligence overwrite

@Test
func updateEnrichmentProvenanceRespectsUserCorrectedMerchant() async throws {
    let db = try makeDB()
    let (_, txnId) = try await insertLedgerAndTransaction(in: db)
    let repo = GRDBTransactionRepository(dbQueue: db)

    // First: set a user-corrected merchant
    try await repo.updateIntelligence(id: txnId, categoryId: nil, merchantName: "My Custom Name")
    try await repo.markUserCorrectedMerchant(id: txnId)

    // Then: pipeline tries to overwrite merchant
    try await repo.updateEnrichmentProvenance(
        id: txnId,
        EnrichmentProvenance(
            categoryId: "food",
            merchantName: "Intelligence Overwrite",
            intelligenceSource: "knn"
        )
    )

    let fetched = try await db.read { db in
        try Transaction.filter(Transaction.Columns.id == txnId).fetchOne(db)
    }
    // Merchant must NOT be overwritten
    #expect(fetched?.merchantName == "My Custom Name")
    // Category IS updated (only merchant is protected)
    #expect(fetched?.categoryId == "food")
    #expect(fetched?.isUserCorrectedMerchant == true)
}

// MARK: - markUserCorrectedMerchant sets the flag

@Test
func markUserCorrectedMerchantSetsFlag() async throws {
    let db = try makeDB()
    let (_, txnId) = try await insertLedgerAndTransaction(in: db)
    let repo = GRDBTransactionRepository(dbQueue: db)

    let before = try await db.read { try Transaction.filter(Transaction.Columns.id == txnId).fetchOne($0) }
    #expect(before?.isUserCorrectedMerchant == false)

    try await repo.markUserCorrectedMerchant(id: txnId)

    let after = try await db.read { try Transaction.filter(Transaction.Columns.id == txnId).fetchOne($0) }
    #expect(after?.isUserCorrectedMerchant == true)
}

// MARK: - resolvedPersonId is written during enrichment (INTEL-016)

@Test
func updateEnrichmentProvenanceWritesResolvedPersonId() async throws {
    let db = try makeDB()
    let (_, txnId) = try await insertLedgerAndTransaction(in: db)
    let repo = GRDBTransactionRepository(dbQueue: db)
    let personId = UUID().uuidString

    try await repo.updateEnrichmentProvenance(
        id: txnId,
        EnrichmentProvenance(resolvedPersonId: personId)
    )

    let fetched = try await db.read { try Transaction.filter(Transaction.Columns.id == txnId).fetchOne($0) }
    #expect(fetched?.resolvedPersonId == personId)
}

// MARK: - nil fields use COALESCE (preserve existing values)

@Test
func updateEnrichmentProvenancePreservesExistingWhenNil() async throws {
    let db = try makeDB()
    let (_, txnId) = try await insertLedgerAndTransaction(in: db)
    let repo = GRDBTransactionRepository(dbQueue: db)

    try await repo.updateIntelligence(id: txnId, categoryId: "food", merchantName: "Zepto")
    try await repo.updateEnrichmentProvenance(
        id: txnId,
        EnrichmentProvenance(intelligenceSource: "knn")
    )

    let fetched = try await db.read { try Transaction.filter(Transaction.Columns.id == txnId).fetchOne($0) }
    // categoryId and merchantName unchanged because provenance passed nil
    #expect(fetched?.categoryId == "food")
    #expect(fetched?.merchantName == "Zepto")
    #expect(fetched?.intelligenceSource == "knn")
}
