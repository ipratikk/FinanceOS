//
//  Transaction.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

/// Indicates whether money left (debit) or entered (credit) the ledger.
public enum TransactionType: String, Sendable, Codable {
    case debit
    case credit
}

/// Core financial event persisted in SQLite. Belongs to a ``Ledger`` and is immutable after import.
/// Amounts are always stored as minor units (e.g. paise for INR) to avoid floating-point rounding.
public struct Transaction:
    Identifiable,
    Codable,
    Sendable,
    FetchableRecord,
    PersistableRecord {
    public let id: UUID
    /// Foreign key to the parent ``Ledger``; nil only for orphaned/in-flight transactions.
    public let ledgerId: UUID?
    /// Denormalised account reference for queries that bypass the ledger join.
    public let accountID: UUID?
    /// Denormalised card reference; populated when the ledger kind is ``LedgerKind/creditCard``.
    public let cardID: UUID?
    public let postedAt: Date
    public let description: String
    /// Transaction amount in currency minor units (e.g. paise). Always positive; sign conveyed by `transactionType`.
    public let amountMinorUnits: Int64
    public let currencyCode: String
    public let transactionType: TransactionType
    /// Deterministic hash produced by the parser used to deduplicate reimported statements.
    public let sourceFingerprint: String?
    /// Predicted or user-confirmed category ID from the intelligence layer. Matches CategoryTaxonomy IDs.
    public let categoryId: String?
    /// Canonical merchant name resolved by MerchantNormalizer.
    public let merchantName: String?
    /// Account closing balance (in minor units) after this transaction, from bank statements with a running balance.
    public let closingBalanceMinorUnits: Int64?

    public init(
        id: UUID = UUID(),
        ledgerId: UUID? = nil,
        accountID: UUID? = nil,
        cardID: UUID? = nil,
        postedAt: Date,
        description: String,
        amountMinorUnits: Int64,
        currencyCode: String,
        transactionType: TransactionType = .debit,
        sourceFingerprint: String? = nil,
        categoryId: String? = nil,
        merchantName: String? = nil,
        closingBalanceMinorUnits: Int64? = nil
    ) {
        self.id = id
        self.ledgerId = ledgerId
        self.accountID = accountID
        self.cardID = cardID
        self.postedAt = postedAt
        self.description = description
        self.amountMinorUnits = amountMinorUnits
        self.currencyCode = currencyCode
        self.transactionType = transactionType
        self.sourceFingerprint = sourceFingerprint
        self.categoryId = categoryId
        self.merchantName = merchantName
        self.closingBalanceMinorUnits = closingBalanceMinorUnits
    }
}

public extension Transaction {
    /// GRDB column references for type-safe query building; mirrors the `transactions` table schema.
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let ledgerId = Column(CodingKeys.ledgerId)
        static let accountID = Column(CodingKeys.accountID)
        static let cardID = Column(CodingKeys.cardID)
        static let postedAt = Column(CodingKeys.postedAt)
        static let description = Column(CodingKeys.description)
        static let amountMinorUnits = Column(CodingKeys.amountMinorUnits)
        static let currencyCode = Column(CodingKeys.currencyCode)
        static let transactionType = Column(CodingKeys.transactionType)
        static let sourceFingerprint = Column(CodingKeys.sourceFingerprint)
        static let categoryId = Column(CodingKeys.categoryId)
        static let merchantName = Column(CodingKeys.merchantName)
        static let closingBalanceMinorUnits = Column(CodingKeys.closingBalanceMinorUnits)
    }
}

public extension Transaction {
    static let databaseTableName = "transactions"

    /// Creates the `transactions` table with all required columns, indexes, and the
    /// `(ledgerId, sourceFingerprint)` unique constraint that powers deduplication.
    static func createTable(
        in database: Database
    ) throws {
        try database.create(
            table: databaseTableName
        ) { table in
            table.column("id", .text)
                .primaryKey()

            table.column("ledgerId", .text)
                .indexed()
                .references(
                    Ledger.databaseTableName,
                    column: "id",
                    onDelete: .cascade
                )

            table.column("accountID", .text)
                .indexed()

            table.column("cardID", .text)
                .indexed()

            table.column("postedAt", .datetime)
                .notNull()
                .indexed()

            table.column("description", .text)
                .notNull()

            table.column("amountMinorUnits", .integer)
                .notNull()

            table.column("currencyCode", .text)
                .notNull()

            table.column("transactionType", .text)
                .notNull()
                .defaults(to: "debit")

            table.column("sourceFingerprint", .text)

            table.column("closingBalanceMinorUnits", .integer)

            table.uniqueKey(["ledgerId", "sourceFingerprint"])
        }
    }
}
