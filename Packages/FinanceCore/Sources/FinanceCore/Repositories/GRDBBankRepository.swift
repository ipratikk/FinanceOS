//
//  GRDBBankRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 15/05/26.
//

import Foundation
import GRDB

public final class GRDBBankRepository:
    @unchecked Sendable,
    BankRepository
{
    private let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func fetchBanks() async throws -> [Bank] {
        try await dbQueue.read { db in
            try Bank.fetchAll(db)
        }
    }

    public func insert(_ bank: Bank) async throws {
        try await dbQueue.write { db in
            try bank.insert(db)
        }
    }

    public func update(_ bank: Bank) async throws {
        try await dbQueue.write { db in
            try bank.update(db)
        }
    }

    public func delete(id: UUID) async throws {
        try await dbQueue.write { db in
            try Bank.deleteOne(db, key: id)
        }
    }
}
