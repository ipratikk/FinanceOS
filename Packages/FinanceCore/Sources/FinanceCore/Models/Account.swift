//
//  Account.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

public enum AccountType: String, Codable, Sendable, CaseIterable {
    case savings, current, credit
}

public struct Account:
    Identifiable,
    Codable,
    Sendable,
    FetchableRecord,
    PersistableRecord
{
    public let id: UUID

    public let bankId: UUID

    public let accountName: String

    public let accountLast4: String

    public let ownerName: String

    public let accountType: AccountType

    public let nickname: String

    public init(
        id: UUID = UUID(),
        bankId: UUID,
        accountName: String,
        accountLast4: String = "",
        ownerName: String = "",
        accountType: AccountType = .savings,
        nickname: String = ""
    ) {
        self.id = id
        self.bankId = bankId
        self.accountName = accountName
        self.accountLast4 = accountLast4
        self.ownerName = ownerName
        self.accountType = accountType
        self.nickname = nickname
    }
}

public extension Account {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let bankId = Column(CodingKeys.bankId)
        static let accountName = Column(CodingKeys.accountName)
        static let accountLast4 = Column(CodingKeys.accountLast4)
        static let ownerName = Column(CodingKeys.ownerName)
        static let accountType = Column(CodingKeys.accountType)
        static let nickname = Column(CodingKeys.nickname)
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

            table.column("bankId", .text)
                .notNull()
                .indexed()
                .references(
                    "banks",
                    column: "id",
                    onDelete: .cascade
                )

            table.column("accountName", .text)
                .notNull()

            table.column("accountLast4", .text)
                .notNull()
                .defaults(to: "")

            table.column("ownerName", .text)
                .notNull()
                .defaults(to: "")

            table.column("accountType", .text)
                .notNull()
                .defaults(to: "savings")

            table.column("nickname", .text)
                .notNull()
                .defaults(to: "")
        }
    }
}
