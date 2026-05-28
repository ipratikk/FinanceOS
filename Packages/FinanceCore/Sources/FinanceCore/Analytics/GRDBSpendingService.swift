import Foundation
import GRDB

public actor GRDBSpendingService: SpendingServiceProtocol {
    private let dbQueue: DatabaseQueue
    private let transactionRepository: any TransactionRepository
    private let ledgerRepository: any LedgerRepository

    public init(
        dbQueue: DatabaseQueue,
        transactionRepository: any TransactionRepository,
        ledgerRepository: any LedgerRepository
    ) {
        self.dbQueue = dbQueue
        self.transactionRepository = transactionRepository
        self.ledgerRepository = ledgerRepository
    }

    public func monthlySummary(months: Int?) async throws -> [MonthlySpendingSummary] {
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

        let sorted = summaryByMonth
            .map { MonthlySpendingSummary(month: $0.key, totalDebit: $0.value.debit, totalCredit: $0.value.credit) }
            .sorted { $0.month < $1.month }
        if let months { return Array(sorted.suffix(months)) }
        return sorted
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
            if txn.transactionType == .debit {
                totalDebit += txn.amountMinorUnits
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

    public func netWorthTimeSeries(months: Int?) async throws -> [NetWorthPoint] {
        let calendar = Calendar.current
        let now = Date()

        let assetKinds: Set<LedgerKind> = [.bankAccount, .wallet, .crypto, .investment]
        let liabilityKinds: Set<LedgerKind> = [.creditCard, .loan]

        var openingTotal: Decimal = 0
        for kind in assetKinds {
            let ledgers = try await ledgerRepository.fetchLedgers(kind: kind)
            openingTotal += ledgers.compactMap(\.openingBalance).reduce(Decimal(0)) { $0 + Decimal($1) / 100 }
        }
        for kind in liabilityKinds {
            let ledgers = try await ledgerRepository.fetchLedgers(kind: kind)
            openingTotal -= ledgers.compactMap(\.openingBalance).reduce(Decimal(0)) { $0 + Decimal($1) / 100 }
        }

        let allLedgers = try await ledgerRepository.fetchLedgers()
        let ledgerKindById = Dictionary(uniqueKeysWithValues: allLedgers.map { ($0.id, $0.kind) })
        let allTransactions = try await transactionRepository.fetchTransactions()

        var byDay: [Date: Decimal] = [:]
        for txn in allTransactions {
            guard let ledgerId = txn.ledgerId,
                  let kind = ledgerKindById[ledgerId],
                  let dayStart = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: txn.postedAt))
            else { continue }

            let delta: Decimal = if assetKinds.contains(kind) {
                txn.transactionType == .credit
                    ? Decimal(txn.amountMinorUnits) / 100
                    : -(Decimal(txn.amountMinorUnits) / 100)
            } else {
                txn.transactionType == .debit
                    ? Decimal(txn.amountMinorUnits) / 100
                    : -(Decimal(txn.amountMinorUnits) / 100)
            }
            byDay[dayStart, default: 0] += delta
        }

        let sortedDays = byDay.keys.sorted()
        let windowStart: Date = if let months,
                                   let cutoff = calendar.date(byAdding: .month, value: -months, to: now),
                                   let ws = calendar.date(from: calendar.dateComponents(
                                       [.year, .month, .day],
                                       from: cutoff
                                   )) {
            ws
        } else {
            sortedDays.first ?? now
        }

        var running: Decimal = openingTotal
        for day in sortedDays where day < windowStart {
            running += byDay[day] ?? 0
        }

        var points: [NetWorthPoint] = []
        var day = windowStart
        while day <= now {
            if let delta = byDay[day] { running += delta }
            points.append(NetWorthPoint(timestamp: day, netWorth: running))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return points
    }
}
