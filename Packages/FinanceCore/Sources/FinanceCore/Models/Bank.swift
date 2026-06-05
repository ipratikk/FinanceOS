//
//  Bank.swift
//  FinanceCore
//
//  Created by Pratik Goel on 15/05/26.
//

import Foundation
import GRDB

/// Broad classification of a financial institution's business model.
/// Used to group or filter ledgers by provider category.
public enum BankProviderType: String, Codable, Sendable, CaseIterable {
    /// Traditional regulated bank (e.g. HDFC, ICICI).
    case bank
    /// Digital-first / app-only bank.
    case neobank
    /// Pure credit issuer with no savings product (e.g. Amex, Scapia).
    case credit
}

/// Enumeration of institutions whose statements FinanceOS can parse and display.
/// Adding a new bank requires a corresponding parser in FinanceParsers.
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

    /// Asset catalog name for the full bank logo image.
    public var logoAssetName: String {
        rawValue.lowercased() + "-logo"
    }

    /// Asset catalog name for the compact bank symbol/icon.
    public var symbolAssetName: String {
        rawValue.lowercased() + "-symbol"
    }

    /// Abbreviated identifier used in UI labels where space is constrained.
    public var shortCode: String {
        switch self {
        case .hdfc: return "HDFC"
        case .icici: return "ICICI"
        case .amex: return "AMEX"
        case .scapia: return "SCA"
        }
    }
}

/// Persisted record representing one financial institution. Seeded once at app launch;
/// each row anchors ``Ledger`` records via a foreign key.
public struct Bank:
    Identifiable,
    Codable,
    Sendable,
    FetchableRecord,
    PersistableRecord {
    public let id: UUID
    /// References the corresponding ``Banks`` enum case; determines display and parser routing.
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
    /// GRDB column references for type-safe query building.
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

    /// Creates the `banks` table. The schema is minimal by design — display attributes are resolved
    /// at runtime from the ``Banks`` enum rather than stored redundantly.
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
