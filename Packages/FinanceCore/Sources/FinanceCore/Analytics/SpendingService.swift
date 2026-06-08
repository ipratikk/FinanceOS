import Foundation

/// Async read-only contract for analytics data consumed by the dashboard and analytics ViewModels.
/// Implementations (e.g. `GRDBSpendingService`) may aggregate on-the-fly from raw transactions.
public protocol SpendingServiceProtocol: Sendable {
    /// Returns per-month debit/credit totals, optionally capped to the last `months` months.
    func monthlySummary(months: Int?) async throws -> [MonthlySpendingSummary]
    /// Returns debit/credit totals and transaction count for the current calendar month.
    func currentMonthTotals() async throws -> SpendingTotals
    /// Returns the most recent `limit` transactions ordered by posting date descending.
    func recentTransactions(limit: Int) async throws -> [Transaction]
    /// Returns daily net-worth snapshots, optionally limited to the last `months` months.
    func netWorthTimeSeries(months: Int?) async throws -> [NetWorthPoint]
}

// MARK: - Chart Models

/// High-level spending categories used for classification and analytics charts.
public enum TransactionCategory: String, Codable, Equatable, Sendable, CaseIterable {
    case food, transport, utilities, entertainment, shopping, healthcare, finance, income, transfer, other
}

/// A single point on the net-worth time-series chart; `netWorthMinorUnits` is in minor currency units (paise, not rupees).
/// Display layer divides by 100 to show rupees.
public struct NetWorthPoint: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let netWorthMinorUnits: Int64

    public init(timestamp: Date, netWorthMinorUnits: Int64) {
        id = UUID()
        self.timestamp = timestamp
        self.netWorthMinorUnits = netWorthMinorUnits
    }
}

extension NetWorthPoint: Equatable {
    public static func == (lhs: NetWorthPoint, rhs: NetWorthPoint) -> Bool {
        lhs.timestamp == rhs.timestamp && lhs.netWorthMinorUnits == rhs.netWorthMinorUnits
    }
}

// MARK: - Aggregate Models

/// Aggregated debit and credit totals for a single calendar month; amounts are in minor units (paise).
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

/// Snapshot of current-month debit, credit, and count used by the dashboard summary card.
/// Amounts are in minor units (paise).
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
