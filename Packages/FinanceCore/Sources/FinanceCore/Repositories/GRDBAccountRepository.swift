//
//  GRDBAccountRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

public final class GRDBAccountRepository:
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
                .order(Account.Columns.name)
                .fetchAll(database)
        }
    }
}
