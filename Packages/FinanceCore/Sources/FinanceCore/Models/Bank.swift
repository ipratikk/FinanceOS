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

public enum Banks: String, Codable, Sendable, CaseIterable {
    case hdfc, icici, amex, scapia

    public var displayName: String {
        switch self {
        case .hdfc:
            return "HDFC Bank"
        case .icici:
            return "ICICI Bank"
        case .amex:
            return "American Express"
        case .scapia:
            return "Scapia"
        }
    }

    public var providerType: BankProviderType {
        switch self {
        case .amex, .scapia:
            return .credit
        default:
            return .bank
        }
    }

    public var logoAssetName: String {
        rawValue.lowercased() + "-logo"
    }

    public var symbolAssetName: String {
        rawValue.lowercased() + "-symbol"
    }
}

public struct Bank:
    Identifiable,
    Codable,
    Sendable,
    FetchableRecord,
    PersistableRecord
{
    public let id: UUID
    public let bank: Banks

    public init(
        id: UUID = UUID(),
        bank: Banks
    ) {
        self.id = id
        self.bank = bank
    }
}

public extension Bank {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let bank = Column(CodingKeys.bank)
    }

    var name: String {
        bank.displayName
    }

    var providerType: BankProviderType {
        bank.providerType
    }

    var logoAssetName: String {
        bank.logoAssetName
    }

    var symbolAssetName: String {
        bank.symbolAssetName
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

            table.column("bank", .text)
                .notNull()
        }
    }
}
