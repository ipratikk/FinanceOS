import Foundation

/// How overdue a ledger's statement is relative to its ``StatementStalenessPolicy``.
public enum StatementStatusLevel: String, Codable, Sendable, CaseIterable {
    case fresh
    case due
    case overdue
    case unknown

    /// Lower rank sorts first: things needing action surface at the top.
    public var sortRank: Int {
        switch self {
        case .overdue: return 0
        case .unknown: return 1
        case .due: return 2
        case .fresh: return 3
        }
    }

    /// True when the user should upload a statement for this ledger.
    public var needsAction: Bool {
        self != .fresh
    }
}

/// Backend-independent input row for statement status evaluation.
/// Built from the GraphQL ledger query; kept free of GRDB and Apollo types.
public struct StatementLedgerInput: Sendable, Equatable {
    public let ledgerId: String
    public let displayName: String
    public let kind: LedgerKind
    public let last4: String
    public let bankName: String
    /// Balance in minor units (paise / cents). Nil when the backend has no balance yet.
    public let balanceMinor: Int64?
    public let currencyCode: String
    /// Date of the most recent imported statement. Nil when none imported.
    public let lastStatementDate: Date?

    public init(
        ledgerId: String,
        displayName: String,
        kind: LedgerKind,
        last4: String,
        bankName: String,
        balanceMinor: Int64?,
        currencyCode: String,
        lastStatementDate: Date?
    ) {
        self.ledgerId = ledgerId
        self.displayName = displayName
        self.kind = kind
        self.last4 = last4
        self.bankName = bankName
        self.balanceMinor = balanceMinor
        self.currencyCode = currencyCode
        self.lastStatementDate = lastStatementDate
    }
}

/// Evaluated freshness for one ledger. Output of ``StatementStatusEvaluator``.
public struct StatementStatus: Sendable, Equatable, Identifiable {
    public var id: String {
        ledgerId
    }

    public let ledgerId: String
    public let displayName: String
    public let kind: LedgerKind
    public let last4: String
    public let bankName: String
    public let balanceMinor: Int64?
    public let currencyCode: String
    public let lastStatementDate: Date?
    public let daysSinceStatement: Int?
    public let level: StatementStatusLevel

    public init(
        ledgerId: String,
        displayName: String,
        kind: LedgerKind,
        last4: String,
        bankName: String,
        balanceMinor: Int64?,
        currencyCode: String,
        lastStatementDate: Date?,
        daysSinceStatement: Int?,
        level: StatementStatusLevel
    ) {
        self.ledgerId = ledgerId
        self.displayName = displayName
        self.kind = kind
        self.last4 = last4
        self.bankName = bankName
        self.balanceMinor = balanceMinor
        self.currencyCode = currencyCode
        self.lastStatementDate = lastStatementDate
        self.daysSinceStatement = daysSinceStatement
        self.level = level
    }
}

/// Maximum acceptable statement age per ledger kind, in days.
/// Defaults are assumptions; tune here, not at call sites.
public struct StatementStalenessPolicy: Sendable, Equatable {
    /// Days before a statement counts as overdue for each kind.
    public let maxAgeDays: [LedgerKind: Int]
    /// Used for kinds missing from ``maxAgeDays``.
    public let fallbackMaxAgeDays: Int
    /// Statements within this many days of the limit are reported as ``StatementStatusLevel/due``.
    public let dueWindowDays: Int

    public init(maxAgeDays: [LedgerKind: Int], fallbackMaxAgeDays: Int, dueWindowDays: Int) {
        self.maxAgeDays = maxAgeDays
        self.fallbackMaxAgeDays = fallbackMaxAgeDays
        self.dueWindowDays = dueWindowDays
    }

    public static let standard = StatementStalenessPolicy(
        maxAgeDays: [
            .bankAccount: 35,
            .creditCard: 35,
            .loan: 35,
            .wallet: 35,
            .crypto: 90,
            .investment: 90
        ],
        fallbackMaxAgeDays: 35,
        dueWindowDays: 7
    )

    public func maxAge(for kind: LedgerKind) -> Int {
        maxAgeDays[kind] ?? fallbackMaxAgeDays
    }
}
