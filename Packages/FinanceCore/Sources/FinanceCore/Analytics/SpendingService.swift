import Foundation

public protocol SpendingServiceProtocol: Sendable {
    func monthlySummary(months: Int) async throws -> [MonthlySpendingSummary]
    func currentMonthTotals() async throws -> SpendingTotals
    func recentTransactions(limit: Int) async throws -> [Transaction]
}

public struct MonthlySpendingSummary: Identifiable, Codable, Equatable, Sendable {
    public let id: Date
    public let month: Date
    public let totalDebit: Int64
    public let totalCredit: Int64

    public init(month: Date, totalDebit: Int64, totalCredit: Int64) {
        self.month = month
        self.id = month
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
