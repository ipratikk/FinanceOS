import Foundation
import GRDB

public struct Ledger:
    Identifiable,
    Codable,
    Sendable,
    FetchableRecord,
    PersistableRecord,
    Equatable {
    public let id: UUID
    public let bankId: UUID
    public let kind: LedgerKind

    public let displayName: String
    public let last4: String
    public let nickname: String
    public let ownerName: String
    public let createdAt: Date

    public let accountType: String?
    public let cardType: CardNetwork?
    public let cardProductId: String?
    public let bin: String? // Bank Identification Number for card network auto-detection
    public let linkedLedgerId: UUID?

    public let isArchived: Bool
    public let closingBalance: Int64?
    public let closingBalanceAsOf: Date?

    /// Explicit CodingKeys so cardProductId serializes as "cardProduct" (preserves DB column name)
    public enum CodingKeys: String, CodingKey {
        case id
        case bankId
        case kind
        case displayName
        case last4
        case nickname
        case ownerName
        case createdAt
        case accountType
        case cardType
        case cardProductId = "cardProduct"
        case bin
        case linkedLedgerId
        case isArchived
        case closingBalance
        case closingBalanceAsOf
    }

    public init(
        id: UUID = UUID(),
        bankId: UUID,
        kind: LedgerKind,
        displayName: String,
        last4: String = "",
        nickname: String = "",
        ownerName: String = "",
        createdAt: Date = Date(),
        accountType: String? = nil,
        cardType: CardNetwork? = nil,
        cardProductId: String? = nil,
        bin: String? = nil,
        linkedLedgerId: UUID? = nil,
        isArchived: Bool = false,
        closingBalance: Int64? = nil,
        closingBalanceAsOf: Date? = nil
    ) {
        self.id = id
        self.bankId = bankId
        self.kind = kind
        self.displayName = displayName
        self.last4 = last4
        self.nickname = nickname
        self.ownerName = ownerName
        self.createdAt = createdAt
        self.accountType = accountType
        self.cardType = cardType
        self.cardProductId = cardProductId
        self.bin = bin
        self.linkedLedgerId = linkedLedgerId
        self.isArchived = isArchived
        self.closingBalance = closingBalance
        self.closingBalanceAsOf = closingBalanceAsOf
    }
}

public extension Ledger {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let bankId = Column(CodingKeys.bankId)
        static let kind = Column(CodingKeys.kind)
        static let displayName = Column(CodingKeys.displayName)
        static let last4 = Column(CodingKeys.last4)
        static let nickname = Column(CodingKeys.nickname)
        static let ownerName = Column(CodingKeys.ownerName)
        static let createdAt = Column(CodingKeys.createdAt)
        static let accountType = Column(CodingKeys.accountType)
        static let cardType = Column(CodingKeys.cardType)
        static let cardProductId = Column(CodingKeys.cardProductId)
        static let bin = Column(CodingKeys.bin)
        static let linkedLedgerId = Column(CodingKeys.linkedLedgerId)
        static let isArchived = Column(CodingKeys.isArchived)
        static let closingBalance = Column(CodingKeys.closingBalance)
        static let closingBalanceAsOf = Column(CodingKeys.closingBalanceAsOf)
    }
}

public extension Ledger {
    static let databaseTableName = "ledgers"

    static func createTable(in database: Database) throws {
        try database.create(table: databaseTableName) { table in
            table.column("id", .text)
                .primaryKey()

            table.column("bankId", .text)
                .notNull()
                .indexed()
                .references(Bank.databaseTableName, column: "id", onDelete: .cascade)

            table.column("kind", .text)
                .notNull()
                .indexed()

            table.column("displayName", .text)
                .notNull()

            table.column("last4", .text)
                .notNull()
                .defaults(to: "")

            table.column("nickname", .text)
                .notNull()
                .defaults(to: "")

            table.column("ownerName", .text)
                .notNull()
                .defaults(to: "")

            table.column("createdAt", .datetime)
                .notNull()
                .defaults(to: Date())

            table.column("accountType", .text)

            table.column("cardType", .text)

            table.column("cardProduct", .text)

            table.column("bin", .text)

            table.column("linkedLedgerId", .text)
                .indexed()
                .references(databaseTableName, column: "id", onDelete: .cascade)

            table.column("isArchived", .integer)
                .notNull()
                .defaults(to: false)

            table.column("closingBalance", .integer)

            table.column("closingBalanceAsOf", .datetime)

            table.check(
                sql: "kind IN ('bankAccount','creditCard','loan','wallet','crypto','investment')"
            )
        }

        try database.execute(sql: """
            CREATE INDEX idx_ledgers_bank_kind ON \(databaseTableName)(bankId, kind)
        """)
    }
}

public extension Ledger {
    var cardProductMetadata: CardMetadata? {
        guard let cardProductId else { return nil }
        return CardDatabase.supportedCards().first { $0.id == cardProductId }
    }
}
