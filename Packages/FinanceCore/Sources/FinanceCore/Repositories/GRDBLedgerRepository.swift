import Foundation
import GRDB

public final class GRDBLedgerRepository:
    @unchecked Sendable,
    LedgerRepository
{
    private let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func fetchLedgers() async throws -> [Ledger] {
        try await dbQueue.read { database in
            try Ledger
                .filter(Ledger.Columns.isArchived == false)
                .fetchAll(database)
        }
    }

    public func fetchLedgers(bankId: UUID) async throws -> [Ledger] {
        try await dbQueue.read { database in
            try Ledger
                .filter(Ledger.Columns.bankId == bankId)
                .filter(Ledger.Columns.isArchived == false)
                .fetchAll(database)
        }
    }

    public func fetchLedgers(kind: LedgerKind) async throws -> [Ledger] {
        try await dbQueue.read { database in
            try Ledger
                .filter(Ledger.Columns.kind == kind.rawValue)
                .filter(Ledger.Columns.isArchived == false)
                .fetchAll(database)
        }
    }

    public func fetchLedgers(bankId: UUID, kind: LedgerKind) async throws -> [Ledger] {
        try await dbQueue.read { database in
            try Ledger
                .filter(Ledger.Columns.bankId == bankId)
                .filter(Ledger.Columns.kind == kind.rawValue)
                .filter(Ledger.Columns.isArchived == false)
                .fetchAll(database)
        }
    }

    public func fetchLedger(id: UUID) async throws -> Ledger? {
        try await dbQueue.read { database in
            try Ledger.fetchOne(database, id: id)
        }
    }

    public func insert(_ ledger: Ledger) async throws {
        try await dbQueue.write { database in
            try ledger.insert(database)
        }
    }

    public func update(_ ledger: Ledger) async throws {
        try await dbQueue.write { database in
            try ledger.update(database)
        }
    }

    public func archive(id: UUID) async throws {
        try await dbQueue.write { database in
            try database.execute(
                sql: "UPDATE ledgers SET isArchived = 1 WHERE id = ?",
                arguments: [id.uuidString]
            )
        }
    }

    public func delete(id: UUID) async throws {
        try await dbQueue.write { database in
            let txnCount: Int = try database.scalar(
                "SELECT COUNT(*) FROM transactions WHERE ledgerId = ?",
                arguments: [id.uuidString]
            ) ?? 0

            guard txnCount == 0 else {
                throw RepositoryError.cannotDeleteLedgerWithTransactions(count: txnCount)
            }

            try database.execute(
                sql: "DELETE FROM ledgers WHERE id = ?",
                arguments: [id.uuidString]
            )
        }
    }
}

public enum RepositoryError: Error, Sendable {
    case cannotDeleteLedgerWithTransactions(count: Int)
}
