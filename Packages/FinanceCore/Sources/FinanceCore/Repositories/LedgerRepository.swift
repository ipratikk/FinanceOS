import Foundation

public protocol LedgerRepository: Sendable {
    func fetchLedgers() async throws -> [Ledger]
    func fetchLedgers(bankId: UUID) async throws -> [Ledger]
    func fetchLedgers(kind: LedgerKind) async throws -> [Ledger]
    func fetchLedgers(bankId: UUID, kind: LedgerKind) async throws -> [Ledger]
    func fetchLedger(id: UUID) async throws -> Ledger?

    func insert(_ ledger: Ledger) async throws
    func update(_ ledger: Ledger) async throws
    func updateClosingBalance(id: UUID, balance: Int64, asOf: Date) async throws
    func archive(id: UUID) async throws
    func delete(id: UUID) async throws
}
