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

        let allLedgers = try await ledgerRepository.fetchLedgers()
        let allTransactions = try await transactionRepository.fetchTransactions()
        let txnsByLedger = Dictionary(grouping: allTransactions) { $0.ledgerId }

        let closingBalanceLedgerIds = closingBalanceLedgerIds(from: allTransactions)
        let ledgerById = Dictionary(uniqueKeysWithValues: allLedgers.map { ($0.id, $0) })
        let ledgerKindById = Dictionary(uniqueKeysWithValues: allLedgers.map { ($0.id, $0.kind) })

        let deltaLedgers = allLedgers.filter { !closingBalanceLedgerIds.contains($0.id) }
        let openingTotal = openingNetWorth(
            assetKinds: assetKinds, liabilityKinds: liabilityKinds,
            ledgers: deltaLedgers, txnsByLedger: txnsByLedger
        )
        let deltaByDay = buildDeltaByDay(
            transactions: allTransactions,
            excludeLedgerIds: closingBalanceLedgerIds,
            ledgerKindById: ledgerKindById,
            assetKinds: assetKinds,
            calendar: calendar
        )

        let windowStart = resolveWindowStart(
            months: months,
            sortedDays: deltaByDay.keys.sorted(),
            now: now,
            calendar: calendar
        )
        var running = openingTotal
        for day in deltaByDay.keys.sorted() where day < windowStart {
            running += deltaByDay[day] ?? 0
        }

        var points: [NetWorthPoint] = []
        var day = windowStart
        while day <= now {
            running += deltaByDay[day] ?? 0
            let cbTotal = closingBalanceTotal(
                at: day, ledgerIds: closingBalanceLedgerIds, txnsByLedger: txnsByLedger,
                ledgerById: ledgerById, assetKinds: assetKinds
            )
            points.append(NetWorthPoint(timestamp: day, netWorth: running + cbTotal))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return points
    }

    private func closingBalanceLedgerIds(from transactions: [Transaction]) -> Set<UUID> {
        var ids = Set<UUID>()
        for txn in transactions {
            if txn.closingBalanceMinorUnits != nil, let lid = txn.ledgerId { ids.insert(lid) }
        }
        return ids
    }

    private func buildDeltaByDay(
        transactions: [Transaction],
        excludeLedgerIds: Set<UUID>,
        ledgerKindById: [UUID: LedgerKind],
        assetKinds: Set<LedgerKind>,
        calendar: Calendar
    ) -> [Date: Decimal] {
        var byDay: [Date: Decimal] = [:]
        for txn in transactions {
            guard let ledgerId = txn.ledgerId,
                  !excludeLedgerIds.contains(ledgerId),
                  let kind = ledgerKindById[ledgerId],
                  let dayStart = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: txn.postedAt))
            else { continue }
            let d = Decimal(txn.amountMinorUnits) / 100
            let delta: Decimal = assetKinds.contains(kind)
                ? (txn.transactionType == .credit ? d : -d)
                : (txn.transactionType == .debit ? d : -d)
            byDay[dayStart, default: 0] += delta
        }
        return byDay
    }

    private func closingBalanceTotal(
        at day: Date,
        ledgerIds: Set<UUID>,
        txnsByLedger: [UUID?: [Transaction]],
        ledgerById: [UUID: Ledger],
        assetKinds: Set<LedgerKind>
    ) -> Decimal {
        let calendar = Calendar.current
        var total: Decimal = 0
        for ledgerId in ledgerIds {
            guard let ledger = ledgerById[ledgerId] else { continue }
            let isAsset = assetKinds.contains(ledger.kind)
            let txns = txnsByLedger[ledgerId] ?? []
            let candidate = txns
                .filter { txn in
                    txn.closingBalanceMinorUnits != nil &&
                        calendar
                        .date(from: calendar.dateComponents([.year, .month, .day], from: txn.postedAt)) ??
                        .distantFuture <= day
                }
                .max(by: { $0.postedAt < $1.postedAt })
            let balanceMinorUnits = candidate?.closingBalanceMinorUnits ?? ledger.openingBalance ?? 0
            let balance = Decimal(balanceMinorUnits) / 100
            total += isAsset ? balance : -balance
        }
        return total
    }

    private func resolveWindowStart(months: Int?, sortedDays: [Date], now: Date, calendar: Calendar) -> Date {
        guard let months,
              let cutoff = calendar.date(byAdding: .month, value: -months, to: now),
              let ws = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: cutoff))
        else { return sortedDays.first ?? now }
        return ws
    }

    private func openingNetWorth(
        assetKinds: Set<LedgerKind>,
        liabilityKinds: Set<LedgerKind>,
        ledgers: [Ledger],
        txnsByLedger: [UUID?: [Transaction]]
    ) -> Decimal {
        var total: Decimal = 0
        for ledger in ledgers {
            let isAsset = assetKinds.contains(ledger.kind)
            let isLiability = liabilityKinds.contains(ledger.kind)
            guard isAsset || isLiability else { continue }
            let balance = ledgerOpeningBalance(ledger: ledger, isAsset: isAsset, txnsByLedger: txnsByLedger)
            total += isAsset ? balance : -balance
        }
        return total
    }

    private func ledgerOpeningBalance(ledger: Ledger, isAsset: Bool, txnsByLedger: [UUID?: [Transaction]]) -> Decimal {
        if let opening = ledger.openingBalance { return Decimal(opening) / 100 }
        guard let closing = ledger.closingBalance else { return 0 }
        let cutoff = ledger.closingBalanceAsOf ?? Date.distantFuture
        let ledgerTxns = txnsByLedger[ledger.id] ?? []
        let delta = ledgerTxns
            .filter { $0.postedAt <= cutoff }
            .reduce(Decimal(0)) { sum, txn in
                let d = Decimal(txn.amountMinorUnits) / 100
                return isAsset
                    ? sum + (txn.transactionType == .credit ? d : -d)
                    : sum + (txn.transactionType == .debit ? d : -d)
            }
        return Decimal(closing) / 100 - delta
    }
}
