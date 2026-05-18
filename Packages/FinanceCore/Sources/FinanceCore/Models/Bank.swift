//
//  Bank.swift
//  FinanceCore
//
//  Created by Pratik Goel on 15/05/26.
//

import Foundation
import GRDB

public enum BankProviderType: String, Codable, Sendable, CaseIterable {
    case bank, neobank, credit
}

public struct Bank:
    Identifiable,
    Codable,
    Sendable,
    FetchableRecord,
    PersistableRecord
{
    public let id: UUID

    public let name: String

    public let providerType: BankProviderType

    public init(
        id: UUID = UUID(),
        name: String,
        providerType: BankProviderType = .bank
    ) {
        self.id = id
        self.name = name
        self.providerType = providerType
    }
}

public extension Bank {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let providerType = Column(CodingKeys.providerType)
    }
}

public extension Bank {
    var logoAssetName: String? {
        let lowerName = name.lowercased()
        if lowerName.contains("hdfc") { return "hdfc-logo" }
        if lowerName.contains("icici") { return "icici-logo" }
        if lowerName.contains("amex") { return "amex-logo" }
        return nil
    }

    var symbolAssetName: String? {
        let lowerName = name.lowercased()
        if lowerName.contains("hdfc") { return "hdfc-symbol" }
        if lowerName.contains("icici") { return "icici-symbol" }
        return nil
    }
}

public extension Bank {
    static let databaseTableName = "banks"

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

            table.column("providerType", .text)
                .notNull()
                .defaults(to: "bank")
        }
    }
}
