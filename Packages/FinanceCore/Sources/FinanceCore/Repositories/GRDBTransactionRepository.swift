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

    public func insertTransactions(
        _ transactions: [Transaction]
    ) async throws {
        try await dbQueue.write { database in
            for transaction in transactions {
                try transaction.insert(database)
            }
        }
    }
}
