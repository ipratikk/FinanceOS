//
//  GRDBBankRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 15/05/26.
//

import Foundation
import GRDB

/// GRDB-backed implementation of `BankRepository`. Delegates simple insert/update/delete
/// to the shared `grdbInsert/grdbUpdate/grdbDelete` helpers to avoid boilerplate.
public final class GRDBBankRepository:
    @unchecked Sendable,
    BankRepository {
    private let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func fetchBanks() async throws -> [Bank] {
        try await dbQueue.read { database in
            try Bank.fetchAll(database)
        }
    }

    public func insert(_ bank: Bank) async throws {
        try await grdbInsert(bank, in: dbQueue)
    }

    public func update(_ bank: Bank) async throws {
        try await grdbUpdate(bank, in: dbQueue)
    }

    public func delete(id: UUID) async throws {
        try await grdbDelete(Bank.self, key: id, in: dbQueue)
    }

    public func deleteAll() async throws {
        try await dbQueue.write { database in
            try database.execute(sql: "DELETE FROM \(Bank.databaseTableName)")
        }
    }
}
