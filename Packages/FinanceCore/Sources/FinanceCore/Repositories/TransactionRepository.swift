import Foundation

// MARK: - Focused sub-protocols (ISP)

/// Read-only transaction fetches. Consumers: SpendingService, AnalyticsViewModel,
/// TransactionsViewModel, ImportViewModel, and entity-scoped VMs.
public protocol TransactionReader: Sendable {
    func fetchTransactions() async throws -> [Transaction]
    func fetchTransactionsForLedger(_ ledgerID: UUID) async throws -> [Transaction]
    func fetchTransactionsForAccount(_ accountID: UUID) async throws -> [Transaction]
    func fetchTransactionsForCard(_ cardID: UUID) async throws -> [Transaction]
}

/// Write operations. Consumers: TransactionImportPipeline (insert), deletion VMs (delete).
public protocol TransactionWriter: Sendable {
    func insertTransactions(_ transactions: [Transaction]) async throws -> ImportResult
    func delete(id: UUID) async throws
}

/// Ledger-type migrations. Consumers: CardsViewModel, AccountsViewModel (convert flows only).
public protocol TransactionMigrator: Sendable {
    func migrateTransactions(fromCard cardID: UUID, toAccount accountID: UUID) async throws
    func migrateTransactions(fromAccount accountID: UUID, toCard cardID: UUID) async throws
}

/// ML / category corrections. Consumer: TransactionsViewModel only.
public protocol TransactionIntelligenceWriter: Sendable {
    func updateIntelligence(id: UUID, categoryId: String?, merchantName: String?) async throws
}

// MARK: - Umbrella (backward-compatible composition)

public protocol TransactionRepository: TransactionReader, TransactionWriter, TransactionMigrator,
    TransactionIntelligenceWriter {}
