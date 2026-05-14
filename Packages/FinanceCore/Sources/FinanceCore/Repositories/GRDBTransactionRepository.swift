//
//  GRDBTransactionRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

public final class GRDBTransactionRepository:
    @unchecked Sendable,
    TransactionRepository
{
    private let dbQueue: DatabaseQueue

    public init(
        dbQueue: DatabaseQueue
    ) {
        self.dbQueue = dbQueue
    }

    public func fetchTransactions() async throws -> [Transaction] {
        try await dbQueue.read { database in
            try Transaction
                .order(Transaction.Columns.postedAt.desc)
                .fetchAll(database)
        }
    }

    public func fetchTransactionsForAccount(
        _ accountID: UUID
    ) async throws -> [Transaction] {
        try await dbQueue.read { database in
            try Transaction
                .filter(Transaction.Columns.accountID == accountID)
                .order(Transaction.Columns.postedAt.desc)
                .fetchAll(database)
        }
    }

    public func fetchTransactionsForCard(
        _ cardID: UUID
    ) async throws -> [Transaction] {
        try await dbQueue.read { database in
            try Transaction
                .filter(Transaction.Columns.cardID == cardID)
                .order(Transaction.Columns.postedAt.desc)
                .fetchAll(database)
        }
    }

    public func insertTransactions(
        _ transactions: [Transaction]
    ) async throws -> ImportResult {
        try await dbQueue.write { database in
            var inserted = 0
            var skipped = 0

            for transaction in transactions {
                do {
                    try transaction.insert(database)
                    inserted += 1
                } catch let error as DatabaseError where error.resultCode == .SQLITE_CONSTRAINT {
                    skipped += 1
                }
            }

            return ImportResult(inserted: inserted, skipped: skipped)
        }
    }
}
