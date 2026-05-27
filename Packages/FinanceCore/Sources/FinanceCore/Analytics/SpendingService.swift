import Foundation

public protocol SpendingServiceProtocol: Sendable {
    func monthlySummary(months: Int) async throws -> [MonthlySpendingSummary]
    func currentMonthTotals() async throws -> SpendingTotals
    func recentTransactions(limit: Int) async throws -> [Transaction]
    func netWorthTimeSeries(months: Int) async throws -> [NetWorthPoint]
}

// MARK: - Chart Models

public enum TransactionCategory: String, Codable, Equatable, Sendable, CaseIterable {
    case food, transport, utilities, entertainment, shopping, healthcare, finance, income, transfer, other
}

public struct NetWorthPoint: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let netWorth: Decimal

    public init(timestamp: Date, netWorth: Decimal) {
        id = UUID()
        self.timestamp = timestamp
        self.netWorth = netWorth
    }
}

extension NetWorthPoint: Equatable {
    public static func == (lhs: NetWorthPoint, rhs: NetWorthPoint) -> Bool {
        lhs.timestamp == rhs.timestamp && lhs.netWorth == rhs.netWorth
    }
}

public struct MonthlySpendingPoint: Identifiable, Sendable {
    public let id: UUID
    public let month: Date
    public let spending: Decimal

    public init(month: Date, spending: Decimal) {
        id = UUID()
        self.month = month
        self.spending = spending
    }
}

extension MonthlySpendingPoint: Equatable {
    public static func == (lhs: MonthlySpendingPoint, rhs: MonthlySpendingPoint) -> Bool {
        lhs.month == rhs.month && lhs.spending == rhs.spending
    }
}

public struct ChartHoverState: Equatable, Sendable {
    public let hoveredDate: Date?
    public let nearestNetWorthPoint: NetWorthPoint?
    public let correspondingMonthlySpending: MonthlySpendingPoint?

    public static let idle = ChartHoverState()

    public init(
        hoveredDate: Date? = nil,
        nearestNetWorthPoint: NetWorthPoint? = nil,
        correspondingMonthlySpending: MonthlySpendingPoint? = nil
    ) {
        self.hoveredDate = hoveredDate
        self.nearestNetWorthPoint = nearestNetWorthPoint
        self.correspondingMonthlySpending = correspondingMonthlySpending
    }
}

// MARK: - Aggregate Models

public struct MonthlySpendingSummary: Identifiable, Codable, Equatable, Sendable {
    public let id: Date
    public let month: Date
    public let totalDebit: Int64
    public let totalCredit: Int64

    public init(month: Date, totalDebit: Int64, totalCredit: Int64) {
        self.month = month
        id = month
        self.totalDebit = totalDebit
        self.totalCredit = totalCredit
    }
}

public struct SpendingTotals: Equatable, Sendable {
    public let totalDebit: Int64
    public let totalCredit: Int64
    public let transactionCount: Int

    public init(totalDebit: Int64, totalCredit: Int64, transactionCount: Int) {
        self.totalDebit = totalDebit
        self.totalCredit = totalCredit
        self.transactionCount = transactionCount
    }
}
