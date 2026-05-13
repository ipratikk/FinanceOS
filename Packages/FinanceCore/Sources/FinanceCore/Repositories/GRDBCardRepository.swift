//
//  GRDBCardRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

public final class GRDBCardRepository:
    CardRepository
{
    private let dbQueue: DatabaseQueue

    public init(
        dbQueue: DatabaseQueue
    ) {
        self.dbQueue = dbQueue
    }

    public func fetchCards() async throws -> [Card] {
        try await dbQueue.read { database in
            try Card
                .order(Card.Columns.name)
                .fetchAll(database)
        }
    }
}
