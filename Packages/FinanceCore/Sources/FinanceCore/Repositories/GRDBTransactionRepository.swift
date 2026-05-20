//
//  GRDBTransactionRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB
import OSLog

public final class GRDBTransactionRepository:
    @unchecked Sendable,
    TransactionRepository {
    private let dbQueue: DatabaseQueue
    private let logger = FinanceLogger.repository

    public init(
        dbQueue: DatabaseQueue
    ) {
        self.dbQueue = dbQueue
    }

    public func fetchTransactions() async throws -> [Transaction] {
        try await dbQueue.read { database in
            let txns = try Transaction
                .order(Transaction.Columns.postedAt.desc)
                .fetchAll(database)

            self.logger.logDebug(
                "Fetched {count} transactions",
                ["count": txns.count]
            )

            return txns
        }
    }

    public func fetchTransactionsForAccount(
        _ accountID: UUID
    ) async throws -> [Transaction] {
        try await dbQueue.read { database in
            let txns = try Transaction
                .filter(Transaction.Columns.accountID == accountID)
                .order(Transaction.Columns.postedAt.desc)
                .fetchAll(database)

            self.logger.logDebug(
                "Fetched {count} txns for account",
                ["count": txns.count, "accountId": accountID.uuidString]
            )

            return txns
        }
    }

    public func fetchTransactionsForCard(
        _ cardID: UUID
    ) async throws -> [Transaction] {
        try await dbQueue.read { database in
            let txns = try Transaction
                .filter(Transaction.Columns.cardID == cardID)
                .order(Transaction.Columns.postedAt.desc)
                .fetchAll(database)

            self.logger.logDebug(
                "Fetched {count} txns for card",
                ["count": txns.count, "cardId": cardID.uuidString]
            )

            return txns
        }
    }

    public func insertTransactions(
        _ transactions: [Transaction]
    ) async throws -> ImportResult {
        try await dbQueue.write { database in
            var inserted = 0
            var skipped = 0
            var batchFingerprints = Set<String>()

            for (idx, transaction) in transactions.enumerated() {
                if let fp = transaction.sourceFingerprint {
                    guard batchFingerprints.insert(fp).inserted else {
                        skipped += 1
                        continue
                    }
                }

                do {
                    try transaction.insert(database)
                    inserted += 1
                } catch let error as GRDB.DatabaseError where error.resultCode == .SQLITE_CONSTRAINT {
                    skipped += 1
                    self.logger.logNotice(
                        "Duplicate transaction skipped: {ledgerId}",
                        ["ledgerId": transaction.ledgerId?.uuidString ?? "unknown", "index": String(idx)]
                    )
                }
            }

            self.logger.logInfo(
                "Insert batch complete: {inserted} inserted, {skipped} duplicates",
                ["inserted": String(inserted), "skipped": String(skipped)]
            )

            return ImportResult(inserted: inserted, skipped: skipped)
        }
    }

    public func delete(id: UUID) async throws {
        try await dbQueue.write { database in
            try database.execute(sql: """
                DELETE FROM transactions WHERE "id" = ?
            """, arguments: [id])

            self.logger.logInfo(
                "Transaction deleted",
                ["transactionId": id.uuidString]
            )
        }
    }

    public func migrateTransactions(fromCard cardID: UUID, toAccount accountID: UUID) async throws {
        try await dbQueue.write { database in
            try database.execute(sql: """
                UPDATE transactions
                SET "accountID" = ?, "cardID" = NULL
                WHERE "cardID" = ?
            """, arguments: [accountID, cardID])

            self.logger.logInfo(
                "Migrated txns from card to account",
                ["fromCard": cardID.uuidString, "toAccount": accountID.uuidString]
            )
        }
    }

    public func migrateTransactions(fromAccount accountID: UUID, toCard cardID: UUID) async throws {
        try await dbQueue.write { database in
            try database.execute(sql: """
                UPDATE transactions
                SET "cardID" = ?, "accountID" = NULL
                WHERE "accountID" = ?
            """, arguments: [cardID, accountID])

            self.logger.logInfo(
                "Migrated txns from account to card",
                ["fromAccount": accountID.uuidString, "toCard": cardID.uuidString]
            )
        }
    }
}
