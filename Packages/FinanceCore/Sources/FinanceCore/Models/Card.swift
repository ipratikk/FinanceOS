//
//  Card.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

public enum CardType: String, Codable, Sendable, CaseIterable {
    case visa, mastercard, amex, rupay, other
}

public struct Card:
    Identifiable,
    Codable,
    Sendable,
    FetchableRecord,
    PersistableRecord
{
    public let id: UUID

    public let bankId: UUID

    public let linkedAccountId: UUID?

    public let cardName: String

    public let cardLast4: String

    public let cardType: CardType

    public let nickname: String

    public init(
        id: UUID = UUID(),
        bankId: UUID,
        linkedAccountId: UUID? = nil,
        cardName: String,
        cardLast4: String = "",
        cardType: CardType = .other,
        nickname: String = ""
    ) {
        self.id = id
        self.bankId = bankId
        self.linkedAccountId = linkedAccountId
        self.cardName = cardName
        self.cardLast4 = cardLast4
        self.cardType = cardType
        self.nickname = nickname
    }
}

public extension Card {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let bankId = Column(CodingKeys.bankId)
        static let linkedAccountId = Column(CodingKeys.linkedAccountId)
        static let cardName = Column(CodingKeys.cardName)
        static let cardLast4 = Column(CodingKeys.cardLast4)
        static let cardType = Column(CodingKeys.cardType)
        static let nickname = Column(CodingKeys.nickname)
    }
}

public extension Card {
    static let databaseTableName = "cards"

    static func createTable(
        in database: Database
    ) throws {
        try database.create(
            table: databaseTableName
        ) { table in
            table.column("id", .text)
                .primaryKey()

            table.column("bankId", .text)
                .notNull()
                .indexed()
                .references(
                    "banks",
                    column: "id",
                    onDelete: .cascade
                )

            table.column("linkedAccountId", .text)
                .indexed()
                .references(
                    Account.databaseTableName,
                    column: "id",
                    onDelete: .setNull
                )

            table.column("cardName", .text)
                .notNull()

            table.column("cardLast4", .text)
                .notNull()
                .defaults(to: "")

            table.column("cardType", .text)
                .notNull()
                .defaults(to: "other")

            table.column("nickname", .text)
                .notNull()
                .defaults(to: "")
        }
    }
}
