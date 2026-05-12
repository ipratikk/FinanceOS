//
//  Institution.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

public struct Institution:
    Identifiable,
    Codable,
    Sendable,
    FetchableRecord,
    PersistableRecord
{
    public let id: UUID

    public let name: String

    public init(
        id: UUID = UUID(),
        name: String
    ) {
        self.id = id
        self.name = name
    }
}

extension Institution {
    public static let databaseTableName = "institutions"

    static func createTable(
        in database: Database
    ) throws {
        try database.create(
            table: databaseTableName
        ) { table in
            table.column("id", .text)
                .primaryKey()

            table.column("name", .text)
                .notNull()
        }
    }
}
