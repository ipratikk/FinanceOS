//
//  Transaction.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

public struct Transaction:
    Identifiable,
    Codable,
    Sendable,
    FetchableRecord,
    PersistableRecord
{
    public let id: UUID
    public let accountID: UUID?
    public let cardID: UUID?
    public let postedAt: Date
    public let description: String
    public let amountMinorUnits: Int64
    public let currencyCode: String
    public let sourceFingerprint: String?

    public init(
        id: UUID = UUID(),
        accountID: UUID? = nil,
        cardID: UUID? = nil,
        postedAt: Date,
        description: String,
        amountMinorUnits: Int64,
        currencyCode: String,
        sourceFingerprint: String? = nil
    ) {
        self.id = id
        self.accountID = accountID
        self.cardID = cardID
        self.postedAt = postedAt
        self.description = description
        self.amountMinorUnits = amountMinorUnits
        self.currencyCode = currencyCode
        self.sourceFingerprint = sourceFingerprint
    }
}

public extension Transaction {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let accountID = Column(CodingKeys.accountID)
        static let cardID = Column(CodingKeys.cardID)
        static let postedAt = Column(CodingKeys.postedAt)
        static let description = Column(CodingKeys.description)
        static let amountMinorUnits = Column(CodingKeys.amountMinorUnits)
        static let currencyCode = Column(CodingKeys.currencyCode)
        static let sourceFingerprint = Column(CodingKeys.sourceFingerprint)
    }
}

public extension Transaction {
    static let databaseTableName = "transactions"

    static func createTable(
        in database: Database
    ) throws {
        try database.create(
            table: databaseTableName
        ) { table in
            table.column("id", .text)
                .primaryKey()

            table.column("accountID", .text)
                .indexed()
                .references(
                    Account.databaseTableName,
                    column: "id",
                    onDelete: .cascade
                )

            table.column("cardID", .text)
                .indexed()
                .references(
                    Card.databaseTableName,
                    column: "id",
                    onDelete: .cascade
                )

            table.column("postedAt", .datetime)
                .notNull()
                .indexed()

            table.column("description", .text)
                .notNull()

            table.column("amountMinorUnits", .integer)
                .notNull()

            table.column("currencyCode", .text)
                .notNull()

            table.column("sourceFingerprint", .text)
                .unique(onConflict: .ignore)

            table.check(
                sql: """
                (
                    ("accountID" IS NOT NULL AND "cardID" IS NULL)
                    OR
                    ("accountID" IS NULL AND "cardID" IS NOT NULL)
                )
                """
            )
        }
    }
}
