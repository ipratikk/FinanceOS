import Foundation

/// Persistence contract for `Ledger` records. Owns all CRUD and balance-update operations;
/// archived ledgers are retained in the database and excluded from normal fetch results.
public protocol LedgerRepository: Sendable {
    /// Returns all non-archived ledgers regardless of bank or kind.
    func fetchLedgers() async throws -> [Ledger]
    /// Returns non-archived ledgers belonging to a specific bank.
    func fetchLedgers(bankId: UUID) async throws -> [Ledger]
    /// Returns non-archived ledgers of the given kind (bank account or credit card).
    func fetchLedgers(kind: LedgerKind) async throws -> [Ledger]
    /// Returns non-archived ledgers scoped to a bank and kind simultaneously.
    func fetchLedgers(bankId: UUID, kind: LedgerKind) async throws -> [Ledger]
    /// Fetches a single ledger by primary key; returns nil if not found or archived.
    func fetchLedger(id: UUID) async throws -> Ledger?

    /// Inserts a new ledger row; throws if a ledger with the same ID already exists.
    func insert(_ ledger: Ledger) async throws
    /// Updates all mutable fields on an existing ledger row.
    func update(_ ledger: Ledger) async throws
    /// Overwrites the opening balance; used when the user corrects the initial statement balance.
    func updateOpeningBalance(id: UUID, balance: Int64) async throws
    /// Updates closing balance only when `asOf` is newer than the currently stored date.
    func updateClosingBalance(id: UUID, balance: Int64, asOf: Date) async throws
    /// Soft-deletes a ledger by setting `isArchived = true`; transactions are preserved.
    func archive(id: UUID) async throws
    /// Hard-deletes a ledger; fails with `RepositoryError.deleteFailed` if transactions exist.
    func delete(id: UUID) async throws
}
