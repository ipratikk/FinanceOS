//
//  GRDBAccountRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

public final class GRDBAccountRepository:
    @unchecked Sendable,
    AccountRepository
{
    private let dbQueue: DatabaseQueue

    public init(
        dbQueue: DatabaseQueue
    ) {
        self.dbQueue = dbQueue
    }

    public func fetchAccounts() async throws -> [Account] {
        try await dbQueue.read { database in
            try Account
                .order(Account.Columns.accountName)
                .fetchAll(database)
        }
    }

    public func insert(_ account: Account) async throws {
        try await dbQueue.write { database in
            try account.insert(database)
        }
    }

    public func update(_ account: Account) async throws {
        try await dbQueue.write { database in
            try account.update(database)
        }
    }

    public func delete(id: UUID) async throws {
        try await dbQueue.write { database in
            try Account.deleteOne(database, key: id)
        }
    }
}
