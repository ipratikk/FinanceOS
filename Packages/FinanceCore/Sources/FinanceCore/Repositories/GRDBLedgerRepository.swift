import Foundation
import GRDB
import OSLog

public final class GRDBLedgerRepository:
    @unchecked Sendable,
    LedgerRepository {
    private let dbQueue: DatabaseQueue
    private let logger = FinanceLogger.repository

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func fetchLedgers() async throws -> [Ledger] {
        try await dbQueue.read { database in
            let ledgers = try Ledger
                .filter(Ledger.Columns.isArchived == false)
                .fetchAll(database)

            self.logger.logDebug(
                "Fetched {count} ledgers",
                ["count": String(ledgers.count)]
            )

            return ledgers
        }
    }

    public func fetchLedgers(bankId: UUID) async throws -> [Ledger] {
        try await dbQueue.read { database in
            let ledgers = try Ledger
                .filter(Ledger.Columns.bankId == bankId)
                .filter(Ledger.Columns.isArchived == false)
                .fetchAll(database)

            self.logger.logDebug(
                "Fetched {count} ledgers for bank",
                ["count": String(ledgers.count), "bankId": bankId.uuidString]
            )

            return ledgers
        }
    }

    public func fetchLedgers(kind: LedgerKind) async throws -> [Ledger] {
        try await dbQueue.read { database in
            let ledgers = try Ledger
                .filter(Ledger.Columns.kind == kind.rawValue)
                .filter(Ledger.Columns.isArchived == false)
                .fetchAll(database)

            self.logger.logDebug(
                "Fetched {count} {kind} ledgers",
                ["count": String(ledgers.count), "kind": kind.rawValue]
            )

            return ledgers
        }
    }

    public func fetchLedgers(bankId: UUID, kind: LedgerKind) async throws -> [Ledger] {
        try await dbQueue.read { database in
            let ledgers = try Ledger
                .filter(Ledger.Columns.bankId == bankId)
                .filter(Ledger.Columns.kind == kind.rawValue)
                .filter(Ledger.Columns.isArchived == false)
                .fetchAll(database)

            self.logger.logDebug(
                "Fetched {count} {kind} ledgers for bank",
                ["count": String(ledgers.count), "kind": kind.rawValue, "bankId": bankId.uuidString]
            )

            return ledgers
        }
    }

    public func fetchLedger(id: UUID) async throws -> Ledger? {
        try await dbQueue.read { database in
            let ledger = try Ledger.fetchOne(database, id: id)

            if ledger != nil {
                self.logger.logDebug(
                    "Fetched ledger",
                    ["ledgerId": id.uuidString]
                )
            } else {
                self.logger.logNotice(
                    "Ledger not found",
                    ["ledgerId": id.uuidString]
                )
            }

            return ledger
        }
    }

    public func insert(_ ledger: Ledger) async throws {
        try await dbQueue.write { database in
            try ledger.insert(database)

            self.logger.logInfo(
                "Inserted ledger",
                ["ledgerId": ledger.id.uuidString, "kind": ledger.kind.rawValue]
            )
        }
    }

    public func update(_ ledger: Ledger) async throws {
        try await dbQueue.write { database in
            try ledger.update(database)

            self.logger.logInfo(
                "Updated ledger",
                ["ledgerId": ledger.id.uuidString, "kind": ledger.kind.rawValue]
            )
        }
    }

    public func updateClosingBalance(id: UUID, balance: Int64, asOf: Date) async throws {
        try await dbQueue.write { database in
            try database.execute(
                sql: """
                    UPDATE ledgers
                    SET closingBalance = ?, closingBalanceAsOf = ?
                    WHERE id = ?
                      AND (closingBalanceAsOf IS NULL OR closingBalanceAsOf < ?)
                """,
                arguments: [balance, asOf, id, asOf]
            )

            self.logger.logInfo(
                "Updated closing balance",
                ["ledgerId": id.uuidString, "balance": String(balance)]
            )
        }
    }

    public func archive(id: UUID) async throws {
        try await dbQueue.write { database in
            try database.execute(
                sql: "UPDATE ledgers SET isArchived = 1 WHERE id = ?",
                arguments: [id]
            )

            self.logger.logInfo(
                "Archived ledger",
                ["ledgerId": id.uuidString]
            )
        }
    }

    public func delete(id: UUID) async throws {
        try await dbQueue.write { database in
            do {
                guard let ledger = try Ledger.fetchOne(database, id: id) else {
                    self.logger.logWarning(
                        "Ledger not found for deletion",
                        ["ledgerId": id.uuidString]
                    )
                    throw RepositoryError.notFound(entity: "Ledger", id: id.uuidString)
                }

                let transactionCount = try Transaction.filter(Column("ledgerId") == id).fetchCount(database)
                if transactionCount > 0 {
                    throw RepositoryError.deleteFailed(
                        entity: "Ledger",
                        id: id.uuidString,
                        reason: "Cannot delete ledger with \(transactionCount) transaction(s)"
                    )
                }

                try ledger.delete(database)

                self.logger.logInfo(
                    "Deleted ledger",
                    ["ledgerId": id.uuidString]
                )
            } catch let error as RepositoryError {
                throw error
            } catch let error as GRDB.DatabaseError {
                self.logger.logError(
                    "Delete ledger failed: {error}",
                    ["ledgerId": id.uuidString, "error": error.message ?? error.description]
                )
                throw RepositoryError.deleteFailed(
                    entity: "Ledger",
                    id: id.uuidString,
                    reason: error.message ?? "Unknown database error during delete"
                )
            } catch {
                self.logger.logError(
                    "Delete ledger failed with unexpected error: {error}",
                    ["ledgerId": id.uuidString, "error": String(describing: error)]
                )
                throw RepositoryError.deleteFailed(
                    entity: "Ledger",
                    id: id.uuidString,
                    reason: String(describing: error)
                )
            }
        }
    }
}
