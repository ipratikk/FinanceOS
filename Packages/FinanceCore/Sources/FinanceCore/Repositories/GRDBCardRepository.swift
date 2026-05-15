//
//  GRDBCardRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

public final class GRDBCardRepository:
    @unchecked Sendable,
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
                .order(Card.Columns.cardName)
                .fetchAll(database)
        }
    }

    public func insert(_ card: Card) async throws {
        try await grdbInsert(card, in: dbQueue)
    }

    public func update(_ card: Card) async throws {
        try await grdbUpdate(card, in: dbQueue)
    }

    public func delete(id: UUID) async throws {
        try await grdbDelete(Card.self, key: id, in: dbQueue)
    }
}
