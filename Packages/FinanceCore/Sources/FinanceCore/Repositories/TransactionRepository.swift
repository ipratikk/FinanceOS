import Foundation

// MARK: - Focused sub-protocols (ISP)

/// Read-only transaction fetches. Consumers: SpendingService, AnalyticsViewModel,
/// TransactionsViewModel, ImportViewModel, and entity-scoped VMs.
public protocol TransactionReader: Sendable {
    /// Fetches all transactions across all ledgers, sorted newest-first.
    func fetchTransactions() async throws -> [Transaction]
    /// Fetches all transactions for a specific ledger, sorted newest-first.
    func fetchTransactionsForLedger(_ ledgerID: UUID) async throws -> [Transaction]
    /// Fetches transactions tagged to a bank account ledger, sorted newest-first.
    func fetchTransactionsForAccount(_ accountID: UUID) async throws -> [Transaction]
    /// Fetches transactions tagged to a credit card ledger, sorted newest-first.
    func fetchTransactionsForCard(_ cardID: UUID) async throws -> [Transaction]
}

/// Write operations. Consumers: TransactionImportPipeline (insert), deletion VMs (delete).
public protocol TransactionWriter: Sendable {
    /// Inserts a batch of transactions, skipping duplicates; returns inserted/skipped counts.
    func insertTransactions(_ transactions: [Transaction]) async throws -> ImportResult
    /// Hard-deletes a single transaction by primary key.
    func delete(id: UUID) async throws
}

/// Ledger-type migrations. Consumers: CardsViewModel, AccountsViewModel (convert flows only).
public protocol TransactionMigrator: Sendable {
    /// Reassigns all transactions from a credit card ledger to a bank account ledger.
    func migrateTransactions(fromCard cardID: UUID, toAccount accountID: UUID) async throws
    /// Reassigns all transactions from a bank account ledger to a credit card ledger.
    func migrateTransactions(fromAccount accountID: UUID, toCard cardID: UUID) async throws
}

/// ML / category corrections. Consumer: TransactionsViewModel only.
public protocol TransactionIntelligenceWriter: Sendable {
    /// Persists a category and/or merchant correction produced by the on-device categoriser.
    func updateIntelligence(id: UUID, categoryId: String?, merchantName: String?) async throws

    /// Writes full enrichment provenance after a pipeline pass.
    /// Respects `isUserCorrectedMerchant` — merchant name is never overwritten when that flag is set.
    /// Uses COALESCE semantics: nil fields in `provenance` leave existing column values unchanged.
    func updateEnrichmentProvenance(id: UUID, _ provenance: EnrichmentProvenance) async throws

    /// Marks a transaction's merchant name as user-corrected, preventing future intelligence overwrites.
    func markUserCorrectedMerchant(id: UUID) async throws
}

// MARK: - Umbrella (backward-compatible composition)

/// Full transaction repository combining all focused sub-protocols for injection into AppContainer.
public protocol TransactionRepository: TransactionReader, TransactionWriter, TransactionMigrator,
    TransactionIntelligenceWriter {}
