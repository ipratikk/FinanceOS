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

        for txn in allTransactions {
            guard let monthStart = calendar.date(
                from: calendar.dateComponents([.year, .month], from: txn.postedAt)
            ) else { continue }
            if summaryByMonth[monthStart] == nil { summaryByMonth[monthStart] = (debit: 0, credit: 0) }
            if txn.transactionType == .debit {
                summaryByMonth[monthStart]?.debit += txn.amountMinorUnits
            } else {
                summaryByMonth[monthStart]?.credit += txn.amountMinorUnits
            }
        }

        return summaryByMonth
            .map { MonthlySpendingSummary(month: $0.key, totalDebit: $0.value.debit, totalCredit: $0.value.credit) }
            .sorted { $0.month > $1.month }
            .prefix(months)
            .map(\.self)
    }

    public func currentMonthTotals() async throws -> SpendingTotals {
        let allTransactions = try await transactionRepository.fetchTransactions()
        let calendar = Calendar.current
        let now = Date()
        guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let currentMonthEnd = calendar.date(byAdding: DateComponents(month: 1), to: currentMonthStart)
        else { return SpendingTotals(totalDebit: 0, totalCredit: 0, transactionCount: 0) }

        var totalDebit: Int64 = 0
        var totalCredit: Int64 = 0
        var count = 0

        for txn in allTransactions {
            guard txn.postedAt >= currentMonthStart, txn.postedAt < currentMonthEnd else { continue }
            count += 1
            if txn.transactionType == .debit { totalDebit += txn.amountMinorUnits }
            else { totalCredit += txn.amountMinorUnits }
        }

        return SpendingTotals(totalDebit: totalDebit, totalCredit: totalCredit, transactionCount: count)
    }

    public func recentTransactions(limit: Int) async throws -> [Transaction] {
        let allTransactions = try await transactionRepository.fetchTransactions()
        return Array(allTransactions.prefix(limit))
    }

    public func netWorthTimeSeries(months: Int) async throws -> [NetWorthPoint] {
        let allTransactions = try await transactionRepository.fetchTransactions()
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .month, value: -months, to: Date()) else { return [] }

        var byDay: [Date: Decimal] = [:]
        for txn in allTransactions where txn.cardID == nil {
            guard let dayStart = calendar.date(
                from: calendar.dateComponents([.year, .month, .day], from: txn.postedAt)
            ) else { continue }
            let delta: Decimal = txn.transactionType == .credit
                ? Decimal(txn.amountMinorUnits) / 100
                : -(Decimal(txn.amountMinorUnits) / 100)
            byDay[dayStart, default: 0] += delta
        }

        let openingMinorUnits: Int64 = try await dbQueue.read { database in
            let rows = try Row.fetchAll(
                database,
                sql: "SELECT openingBalance FROM ledgers WHERE kind = 'bankAccount' AND openingBalance IS NOT NULL"
            )
            return rows.reduce(Int64(0)) { sum, row in sum + (row["openingBalance"] as Int64? ?? 0) }
        }

        let sorted = byDay.sorted { $0.key < $1.key }
        var running: Decimal = Decimal(openingMinorUnits) / 100
        var points: [NetWorthPoint] = []
        for (day, delta) in sorted {
            running += delta
            if day >= cutoff { points.append(NetWorthPoint(timestamp: day, netWorth: running)) }
        }
        return points
    }
}
