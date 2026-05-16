import Foundation
import GRDB

public struct Ledger:
    Identifiable,
    Codable,
    Sendable,
    FetchableRecord,
    PersistableRecord,
    Equatable
{
    public let id: UUID
    public let bankId: UUID
    public let kind: LedgerKind

    public let displayName: String
    public let last4: String
    public let nickname: String
    public let ownerName: String
    public let createdAt: Date

    public let accountType: AccountType?
    public let cardType: CardType?
    public let cardProduct: String?
    public let linkedLedgerId: UUID?

    public let isArchived: Bool

    public init(
        id: UUID = UUID(),
        bankId: UUID,
        kind: LedgerKind,
        displayName: String,
        last4: String = "",
        nickname: String = "",
        ownerName: String = "",
        createdAt: Date = Date(),
        accountType: AccountType? = nil,
        cardType: CardType? = nil,
        cardProduct: String? = nil,
        linkedLedgerId: UUID? = nil,
        isArchived: Bool = false
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
        self.cardProduct = cardProduct
        self.linkedLedgerId = linkedLedgerId
        self.isArchived = isArchived
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
        static let cardProduct = Column(CodingKeys.cardProduct)
        static let linkedLedgerId = Column(CodingKeys.linkedLedgerId)
        static let isArchived = Column(CodingKeys.isArchived)
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

            table.column("linkedLedgerId", .text)
                .indexed()
                .references(databaseTableName, column: "id", onDelete: .setNull)

            table.column("isArchived", .integer)
                .notNull()
                .defaults(to: false)

            table.check(
                sql: "kind IN ('bankAccount','creditCard','loan','wallet','crypto','investment')"
            )
        }

        try database.execute(sql: """
            CREATE INDEX idx_ledgers_bank_kind ON \(databaseTableName)(bankId, kind)
        """)
    }
}
