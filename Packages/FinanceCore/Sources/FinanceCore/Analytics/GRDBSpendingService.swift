import Foundation
import GRDB

public actor GRDBSpendingService: SpendingServiceProtocol {
    private let dbQueue: DatabaseQueue
    private let transactionRepository: any TransactionRepository

    public init(dbQueue: DatabaseQueue, transactionRepository: any TransactionRepository) {
        self.dbQueue = dbQueue
        self.transactionRepository = transactionRepository
    }

    public func monthlySummary(months: Int) async throws -> [MonthlySpendingSummary] {
        let allTransactions = try await transactionRepository.fetchTransactions()

        var summaryByMonth: [Date: (debit: Int64, credit: Int64)] = [:]

        let calendar = Calendar.current
        let now = Date()

        for txn in allTransactions {
            guard let monthStart = calendar.date(
                from: calendar.dateComponents([.year, .month], from: txn.postedAt)
            ) else { continue }
            let amount = txn.amountMinorUnits

            if summaryByMonth[monthStart] == nil {
                summaryByMonth[monthStart] = (debit: 0, credit: 0)
            }

            if amount < 0 {
                summaryByMonth[monthStart]?.debit -= amount
            } else {
                summaryByMonth[monthStart]?.credit += amount
            }
        }

        let sortedMonths = summaryByMonth
            .map { month, totals in
                MonthlySpendingSummary(
                    month: month,
                    totalDebit: totals.debit,
                    totalCredit: totals.credit
                )
            }
            .sorted { $0.month > $1.month }
            .prefix(months)

        return Array(sortedMonths)
    }

    public func currentMonthTotals() async throws -> SpendingTotals {
        let allTransactions = try await transactionRepository.fetchTransactions()

        let calendar = Calendar.current
        let now = Date()
        guard let currentMonthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ), let currentMonthEnd = calendar.date(
            byAdding: DateComponents(month: 1),
            to: currentMonthStart
        ) else {
            return SpendingTotals(totalDebit: 0, totalCredit: 0, transactionCount: 0)
        }

        var totalDebit: Int64 = 0
        var totalCredit: Int64 = 0
        var count = 0

        for txn in allTransactions {
            guard txn.postedAt >= currentMonthStart, txn.postedAt < currentMonthEnd else {
                continue
            }

            count += 1
            if txn.amountMinorUnits < 0 {
                totalDebit -= txn.amountMinorUnits
            } else {
                totalCredit += txn.amountMinorUnits
            }
        }

        return SpendingTotals(totalDebit: totalDebit, totalCredit: totalCredit, transactionCount: count)
    }

    public func recentTransactions(limit: Int) async throws -> [Transaction] {
        let allTransactions = try await transactionRepository.fetchTransactions()
        return Array(allTransactions.prefix(limit))
    }
}
