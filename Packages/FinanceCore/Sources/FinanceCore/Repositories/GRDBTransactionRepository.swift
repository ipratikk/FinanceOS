//
//  GRDBTransactionRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB
import OSLog

/// GRDB-backed implementation of the full `TransactionRepository` umbrella protocol.
/// Deduplication during insert uses two layers: an in-batch fingerprint set (catches same-file
/// duplicates) and a SQLite UNIQUE constraint (catches cross-import duplicates).
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

    public func fetchTransactionsForLedger(
        _ ledgerID: String
    ) async throws -> [Transaction] {
        try await dbQueue.read { database in
            let txns = try Transaction
                .filter(Transaction.Columns.ledgerId == ledgerID)
                .order(Transaction.Columns.postedAt.desc)
                .fetchAll(database)

            self.logger.logDebug(
                "Fetched {count} txns for ledger",
                ["count": txns.count, "ledgerId": ledgerID]
            )

            return txns
        }
    }

    public func fetchTransactionsForAccount(
        _ accountID: String
    ) async throws -> [Transaction] {
        try await dbQueue.read { database in
            let txns = try Transaction
                .filter(Transaction.Columns.accountID == accountID)
                .order(Transaction.Columns.postedAt.desc)
                .fetchAll(database)

            self.logger.logDebug(
                "Fetched {count} txns for account",
                ["count": txns.count, "accountId": accountID]
            )

            return txns
        }
    }

    public func fetchTransactionsForCard(
        _ cardID: String
    ) async throws -> [Transaction] {
        try await dbQueue.read { database in
            let txns = try Transaction
                .filter(Transaction.Columns.cardID == cardID)
                .order(Transaction.Columns.postedAt.desc)
                .fetchAll(database)

            self.logger.logDebug(
                "Fetched {count} txns for card",
                ["count": txns.count, "cardId": cardID]
            )

            return txns
        }
    }

    /// Inserts transactions in a single write transaction.
    /// Layer 1: in-batch `batchKeys` set drops same-fingerprint rows before hitting SQLite.
    /// Layer 2: SQLITE_CONSTRAINT catch handles duplicates from prior import sessions.
    public func insertTransactions(
        _ transactions: [Transaction]
    ) async throws -> ImportResult {
        try await dbQueue.write { database in
            var inserted = 0
            var skipped = 0
            var batchKeys = Set<String>()

            for (idx, transaction) in transactions.enumerated() {
                if let fingerprint = transaction.sourceFingerprint {
                    let key = "\(transaction.ledgerId ?? "")|\(fingerprint)"
                    guard batchKeys.insert(key).inserted else {
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
                        ["ledgerId": transaction.ledgerId ?? "unknown", "index": String(idx)]
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

    public func delete(id: String) async throws {
        try await dbQueue.write { database in
            try database.execute(sql: """
                DELETE FROM transactions WHERE "id" = ?
            """, arguments: [id])

            self.logger.logInfo(
                "Transaction deleted",
                ["transactionId": id]
            )
        }
    }

    /// Reassigns card transactions to an account ledger; used when user converts a card to an account.
    public func migrateTransactions(fromCard cardID: String, toAccount accountID: String) async throws {
        try await dbQueue.write { database in
            try database.execute(sql: """
                UPDATE transactions
                SET "accountID" = ?, "cardID" = NULL
                WHERE "cardID" = ?
            """, arguments: [accountID, cardID])

            self.logger.logInfo(
                "Migrated txns from card to account",
                ["fromCard": cardID, "toAccount": accountID]
            )
        }
    }

    /// Reassigns account transactions to a card ledger; used when user converts an account to a card.
    public func migrateTransactions(fromAccount accountID: String, toCard cardID: String) async throws {
        try await dbQueue.write { database in
            try database.execute(sql: """
                UPDATE transactions
                SET "cardID" = ?, "accountID" = NULL
                WHERE "accountID" = ?
            """, arguments: [cardID, accountID])

            self.logger.logInfo(
                "Migrated txns from account to card",
                ["fromAccount": accountID, "toCard": cardID]
            )
        }
    }

    public func updateIntelligence(id: String, categoryId: String?, merchantName: String?) async throws {
        try await dbQueue.write { database in
            try database.execute(sql: """
                UPDATE transactions
                SET "categoryId" = ?, "merchantName" = ?
                WHERE "id" = ?
            """, arguments: [categoryId, merchantName, id])
        }
    }

    public func updateEnrichmentProvenance(id: String, _ provenance: EnrichmentProvenance) async throws {
        try await dbQueue.write { database in
            try database.execute(sql: """
                UPDATE transactions
                SET
                    "categoryId"               = COALESCE(?, "categoryId"),
                    "merchantName"             = CASE WHEN "isUserCorrectedMerchant" = 1
                                                     THEN "merchantName"
                                                     ELSE COALESCE(?, "merchantName") END,
                    "intentId"                 = COALESCE(?, "intentId"),
                    "resolvedPersonId"         = COALESCE(?, "resolvedPersonId"),
                    "lastEnrichedAt"           = ?,
                    "intelligenceSource"       = ?,
                    "intelligenceModelVersion" = ?,
                    "intelligenceConfigVersion" = ?
                WHERE "id" = ?
            """, arguments: [
                provenance.categoryId, provenance.merchantName,
                provenance.intentId, provenance.resolvedPersonId,
                provenance.lastEnrichedAt, provenance.intelligenceSource,
                provenance.intelligenceModelVersion, provenance.intelligenceConfigVersion,
                id
            ])
        }
    }

    public func updateEnrichmentProvenanceBatch(_ updates: [(
        id: String,
        provenance: EnrichmentProvenance
    )]) async throws {
        guard !updates.isEmpty else { return }
        try await dbQueue.write { database in
            for (id, provenance) in updates {
                try database.execute(sql: """
                    UPDATE transactions
                    SET
                        "categoryId"               = COALESCE(?, "categoryId"),
                        "merchantName"             = CASE WHEN "isUserCorrectedMerchant" = 1
                                                         THEN "merchantName"
                                                         ELSE COALESCE(?, "merchantName") END,
                        "intentId"                 = COALESCE(?, "intentId"),
                        "resolvedPersonId"         = COALESCE(?, "resolvedPersonId"),
                        "lastEnrichedAt"           = ?,
                        "intelligenceSource"       = ?,
                        "intelligenceModelVersion" = ?,
                        "intelligenceConfigVersion" = ?
                    WHERE "id" = ?
                """, arguments: [
                    provenance.categoryId, provenance.merchantName,
                    provenance.intentId, provenance.resolvedPersonId,
                    provenance.lastEnrichedAt, provenance.intelligenceSource,
                    provenance.intelligenceModelVersion, provenance.intelligenceConfigVersion,
                    id
                ])
            }
        }
    }

    public func markUserCorrectedMerchant(id: String) async throws {
        try await dbQueue.write { database in
            try database.execute(sql: """
                UPDATE transactions SET "isUserCorrectedMerchant" = 1 WHERE "id" = ?
            """, arguments: [id])
        }
    }

    public func clearUserCorrectedMerchant(id: String) async throws {
        try await dbQueue.write { database in
            try database.execute(sql: """
                UPDATE transactions SET "isUserCorrectedMerchant" = 0 WHERE "id" = ?
            """, arguments: [id])
        }
    }

    public func updateEnrichedDescription(id: String, description: String) async throws {
        try await dbQueue.write { database in
            try database.execute(
                sql: #"UPDATE transactions SET "enrichedDescription" = ? WHERE "id" = ?"#,
                arguments: [description, id]
            )
        }
    }

    public func updateEnrichedDescriptionBatch(_ updates: [(id: String, description: String)]) async throws {
        guard !updates.isEmpty else { return }
        try await dbQueue.write { database in
            for (id, description) in updates {
                try database.execute(
                    sql: #"UPDATE transactions SET "enrichedDescription" = ? WHERE "id" = ?"#,
                    arguments: [description, id]
                )
            }
        }
    }

    public func updateLinkedTransaction(id: String, linkedTransactionId: String) async throws {
        try await dbQueue.write { database in
            try database.execute(
                sql: #"UPDATE transactions SET "linkedTransactionId" = ? WHERE "id" = ?"#,
                arguments: [linkedTransactionId, id]
            )
        }
    }
}
