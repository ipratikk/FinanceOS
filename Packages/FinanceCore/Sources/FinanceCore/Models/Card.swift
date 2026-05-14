//
//  Card.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

public struct Card:
    Identifiable,
    Codable,
    Sendable,
    FetchableRecord,
    PersistableRecord
{
    public let id: UUID

    public let institutionID: UUID

    public let accountID: UUID?

    public let name: String

    public let nickname: String

    public let last4: String

    public init(
        id: UUID = UUID(),
        institutionID: UUID,
        accountID: UUID? = nil,
        name: String,
        nickname: String = "",
        last4: String = ""
    ) {
        self.id = id
        self.institutionID = institutionID
        self.accountID = accountID
        self.name = name
        self.nickname = nickname
        self.last4 = last4
    }
}

public extension Card {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let institutionID = Column(CodingKeys.institutionID)
        static let accountID = Column(CodingKeys.accountID)
        static let name = Column(CodingKeys.name)
        static let nickname = Column(CodingKeys.nickname)
        static let last4 = Column(CodingKeys.last4)
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

            table.column("institutionID", .text)
                .notNull()
                .indexed()
                .references(
                    Institution.databaseTableName,
                    column: "id",
                    onDelete: .cascade
                )

            table.column("accountID", .text)
                .indexed()
                .references(
                    Account.databaseTableName,
                    column: "id",
                    onDelete: .setNull
                )

            table.column("name", .text)
                .notNull()

            table.column("nickname", .text)
                .notNull()
                .defaults(to: "")

            table.column("last4", .text)
                .notNull()
                .defaults(to: "")
        }
    }
}
