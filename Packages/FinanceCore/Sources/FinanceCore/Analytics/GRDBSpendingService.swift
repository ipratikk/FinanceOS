import Foundation
import GRDB

/// GRDB-backed `SpendingServiceProtocol` implementation that aggregates analytics in-memory from raw transactions.
/// All methods fetch the full transaction set and group/filter in Swift rather than SQL to keep queries simple.
public actor GRDBSpendingService: SpendingServiceProtocol {
    private let dbQueue: DatabaseQueue
    private let transactionRepository: any TransactionReader
    private let ledgerRepository: any LedgerRepository

    public init(
        dbQueue: DatabaseQueue,
        transactionRepository: any TransactionReader,
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
            if TransactionFilter.isRealExpense(txn) {
                summaryByMonth[monthStart]?.debit += txn.amountMinorUnits
            } else if TransactionFilter.isRealIncome(txn) {
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
            if TransactionFilter.isRealExpense(txn) {
                count += 1
                totalDebit += txn.amountMinorUnits
            } else if TransactionFilter.isRealIncome(txn) {
                count += 1
                totalCredit += txn.amountMinorUnits
            }
        }

        return SpendingTotals(totalDebit: totalDebit, totalCredit: totalCredit, transactionCount: count)
    }

    public func recentTransactions(limit: Int) async throws -> [Transaction] {
        let allTransactions = try await transactionRepository.fetchTransactions()
        return Array(allTransactions.sorted { $0.postedAt > $1.postedAt }.prefix(limit))
    }

    public func netWorthTimeSeries(months: Int?) async throws -> [NetWorthPoint] {
        let calendar = Calendar.current
        let now = Date()
        let assetKinds: Set<LedgerKind> = [.bankAccount, .wallet, .crypto, .investment]
        let liabilityKinds: Set<LedgerKind> = [.loan]

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
            let majorUnits = running + cbTotal
            let minorUnits = Int64(NSDecimalNumber(decimal: majorUnits * 100).int64Value)
            points.append(NetWorthPoint(timestamp: day, netWorthMinorUnits: minorUnits))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return points
    }

    public func bankAccountBalances(months: Int?) async throws -> [LedgerBalanceTimeSeries] {
        let calendar = Calendar.current
        let now = Date()

        let allLedgers = try await ledgerRepository.fetchLedgers()
        let allTransactions = try await transactionRepository.fetchTransactions()
        let txnsByLedger = Dictionary(grouping: allTransactions) { $0.ledgerId }

        let closingBalanceLedgerIds = closingBalanceLedgerIds(from: allTransactions)
        let ledgerKindById = Dictionary(uniqueKeysWithValues: allLedgers.map { ($0.id, $0.kind) })

        let bankAccountLedgers = allLedgers.filter { $0.kind == .bankAccount }
        let deltaByDayByLedger = buildDeltaByDayPerLedger(
            transactions: allTransactions,
            ledgers: bankAccountLedgers,
            ledgerKindById: ledgerKindById,
            calendar: calendar
        )

        let allDays = Set(deltaByDayByLedger.values.flatMap(\.keys)).sorted()
        let windowStart = resolveWindowStart(
            months: months,
            sortedDays: allDays,
            now: now,
            calendar: calendar
        )

        var results: [LedgerBalanceTimeSeries] = []
        for ledger in bankAccountLedgers {
            let deltaByDay = deltaByDayByLedger[ledger.id] ?? [:]
            let isClosingBalance = closingBalanceLedgerIds.contains(ledger.id)
            let openingBalance = ledgerOpeningBalance(
                ledger: ledger, isAsset: true, txnsByLedger: txnsByLedger
            )

            var running = openingBalance
            for day in allDays where day < windowStart {
                running += deltaByDay[day] ?? 0
            }

            // Collect all statement dates (days with closing balances) for this ledger.
            let statementDates: Set<Date> = Set((txnsByLedger[ledger.id] ?? [])
                .compactMap { txn in
                    guard txn.closingBalanceMinorUnits != nil else { return nil }
                    return calendar.date(from: calendar.dateComponents([.year, .month, .day], from: txn.postedAt))
                })

            var points: [NetWorthPoint] = []
            var day = windowStart
            while day <= now {
                running += deltaByDay[day] ?? 0
                // Only use closing balance if a statement exists FOR THIS EXACT DAY.
                let cbMinorUnits: Decimal? = isClosingBalance && statementDates.contains(day)
                    ? closingBalanceForLedger(
                        at: day, ledgerId: ledger.id, txnsByLedger: txnsByLedger
                    )
                    : nil
                let balance = cbMinorUnits ?? (running * 100)
                let minorUnits = Int64(NSDecimalNumber(decimal: balance).int64Value)
                points.append(NetWorthPoint(timestamp: day, netWorthMinorUnits: minorUnits))
                // Re-anchor running balance to the known-true closing balance so subsequent
                // days accumulate deltas from truth rather than from a drifted opening baseline.
                if let cb = cbMinorUnits {
                    running = cb / 100
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }

            results.append(
                LedgerBalanceTimeSeries(
                    ledgerId: ledger.id,
                    ledgerName: ledger.displayName,
                    ledgerKind: ledger.kind,
                    points: points
                )
            )
        }
        return results
    }

    /// Returns the set of ledger IDs that carry a `closingBalance` on at least one transaction.
    /// These ledgers are treated as authoritative-balance sources rather than delta accumulators.
    private func closingBalanceLedgerIds(from transactions: [Transaction]) -> Set<UUID> {
        var ids = Set<UUID>()
        for txn in transactions {
            if txn.closingBalanceMinorUnits != nil, let lid = txn.ledgerId { ids.insert(lid) }
        }
        return ids
    }

    /// Accumulates signed daily net-worth deltas for all delta-style ledgers (those without closing balances).
    /// Credits add to assets / reduce liabilities; debits do the inverse.
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
                  kind != .creditCard,
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

    /// Accumulates signed daily deltas per ledger for bank account balance progression.
    /// Only processes bank account ledgers; credits add, debits subtract.
    private func buildDeltaByDayPerLedger(
        transactions: [Transaction],
        ledgers: [Ledger],
        ledgerKindById: [UUID: LedgerKind],
        calendar: Calendar
    ) -> [UUID: [Date: Decimal]] {
        var byLedger: [UUID: [Date: Decimal]] = [:]
        for ledger in ledgers {
            byLedger[ledger.id] = [:]
        }
        for txn in transactions {
            guard let ledgerId = txn.ledgerId,
                  byLedger[ledgerId] != nil,
                  let dayStart = calendar.date(
                      from: calendar.dateComponents([.year, .month, .day], from: txn.postedAt)
                  )
            else { continue }
            let d = Decimal(txn.amountMinorUnits) / 100
            let delta = txn.transactionType == .credit ? d : -d
            byLedger[ledgerId]?[dayStart, default: 0] += delta
        }
        return byLedger
    }

    /// Returns the most-recent known closing balance for a specific ledger as of `day`.
    /// Falls back to nil if no closing balance exists for that ledger.
    private func closingBalanceForLedger(
        at day: Date,
        ledgerId: UUID,
        txnsByLedger: [UUID?: [Transaction]]
    ) -> Decimal? {
        let calendar = Calendar.current
        let txns = txnsByLedger[ledgerId] ?? []
        let candidate = txns
            .filter { txn in
                guard txn.closingBalanceMinorUnits != nil else { return false }
                let txnDay = calendar.date(
                    from: calendar.dateComponents([.year, .month, .day], from: txn.postedAt)
                ) ?? .distantFuture
                return txnDay <= day
            }
            .max(by: { $0.postedAt < $1.postedAt })
        guard let balanceMinorUnits = candidate?.closingBalanceMinorUnits else { return nil }
        return Decimal(balanceMinorUnits)
    }

    /// Sums the most-recent known closing balance for each closing-balance ledger as of `day`.
    /// Falls back to the ledger's `openingBalance` if no transaction on or before `day` carries one.
    /// Excludes creditCard ledgers (transient spending flow, not part of net worth).
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
            if ledger.kind == .creditCard { continue }
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

    /// Resolves start-of-window date for chart rendering; defaults to earliest transaction day if `months` is nil.
    private func resolveWindowStart(months: Int?, sortedDays: [Date], now: Date, calendar: Calendar) -> Date {
        guard let months,
              let cutoff = calendar.date(byAdding: .month, value: -months, to: now),
              let ws = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: cutoff))
        else { return sortedDays.first ?? now }
        return ws
    }

    /// Computes the net-worth baseline before the chart window by summing opening/derived balances of delta ledgers.
    /// Excludes creditCard ledgers (transient spending flow, not part of net worth).
    private func openingNetWorth(
        assetKinds: Set<LedgerKind>,
        liabilityKinds: Set<LedgerKind>,
        ledgers: [Ledger],
        txnsByLedger: [UUID?: [Transaction]]
    ) -> Decimal {
        var total: Decimal = 0
        for ledger in ledgers {
            if ledger.kind == .creditCard { continue }
            let isAsset = assetKinds.contains(ledger.kind)
            let isLiability = liabilityKinds.contains(ledger.kind)
            guard isAsset || isLiability else { continue }
            let balance = ledgerOpeningBalance(ledger: ledger, isAsset: isAsset, txnsByLedger: txnsByLedger)
            total += isAsset ? balance : -balance
        }
        return total
    }

    /// Returns a ledger's effective opening balance: uses stored `openingBalance` when present,
    /// otherwise back-computes from `closingBalance` minus the sum of all transactions up to `closingBalanceAsOf`.
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
