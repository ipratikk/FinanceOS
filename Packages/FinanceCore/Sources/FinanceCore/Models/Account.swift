//
//  Account.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

public struct Account:
    Identifiable,
    Codable,
    Sendable,
    FetchableRecord,
    PersistableRecord
{
    public let id: UUID

    public let institutionID: UUID

    public let name: String

    public init(
        id: UUID = UUID(),
        institutionID: UUID,
        name: String
    ) {
        self.id = id
        self.institutionID = institutionID
        self.name = name
    }
}

public extension Account {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let institutionID = Column(CodingKeys.institutionID)
        static let name = Column(CodingKeys.name)
    }
}

public extension Account {
    static let databaseTableName = "accounts"

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

            table.column("name", .text)
                .notNull()
        }
    }
}
