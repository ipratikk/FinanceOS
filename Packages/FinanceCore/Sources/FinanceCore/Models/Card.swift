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

    public init(
        id: UUID = UUID(),
        institutionID: UUID,
        accountID: UUID? = nil,
        name: String
    ) {
        self.id = id
        self.institutionID = institutionID
        self.accountID = accountID
        self.name = name
    }
}

public extension Card {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let institutionID = Column(CodingKeys.institutionID)
        static let accountID = Column(CodingKeys.accountID)
        static let name = Column(CodingKeys.name)
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
        }
    }
}
