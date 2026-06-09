import Foundation
import GRDB

// MARK: - Supporting Types

private struct LedgerSeriesContext {
    let ledger: Ledger
    let deltaByDay: [Date: Decimal]
    let isClosingBalance: Bool
    let txnsByLedger: [UUID?: [Transaction]]
    let allDays: [Date]
    let windowStart: Date
    let now: Date
    let calendar: Calendar
}

// MARK: - Pure Helpers (file-private, no actor isolation needed)

private func spendingClosingBalanceLedgerIds(from transactions: [Transaction]) -> Set<UUID> {
    var ids = Set<UUID>()
    for txn in transactions {
        if txn.closingBalanceMinorUnits != nil, let lid = txn.ledgerId { ids.insert(lid) }
    }
    return ids
}

private func spendingBuildDeltaByDay(
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

private func spendingBuildDeltaByDayPerLedger(
    transactions: [Transaction],
    ledgers: [Ledger],
    calendar: Calendar
) -> [UUID: [Date: Decimal]] {
    var byLedger: [UUID: [Date: Decimal]] = [:]
    for ledger in ledgers {
        byLedger[ledger.id] = [:]
    }
    for txn in transactions {
        guard let ledgerId = txn.ledgerId,
              byLedger[ledgerId] != nil,
              let dayStart = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: txn.postedAt))
        else { continue }
        let d = Decimal(txn.amountMinorUnits) / 100
        let delta = txn.transactionType == .credit ? d : -d
        byLedger[ledgerId]?[dayStart, default: 0] += delta
    }
    return byLedger
}

/// Picks end-of-day closing balance for `ledgerId` on `day`. Tiebreaker: UUID lexicographic.
/// See full rationale in GRDBSpendingService context — UUID is v4 random, not monotonic,
/// but is reproducible across runs (eliminates Set/Dictionary iteration non-determinism).
private func spendingEndOfDayClosingBalance(
    for day: Date,
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
        .max { lhs, rhs in
            let lhsDay = calendar.date(
                from: calendar.dateComponents([.year, .month, .day], from: lhs.postedAt)
            ) ?? .distantPast
            let rhsDay = calendar.date(
                from: calendar.dateComponents([.year, .month, .day], from: rhs.postedAt)
            ) ?? .distantPast
            if lhsDay != rhsDay { return lhsDay < rhsDay }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    guard let balanceMinorUnits = candidate?.closingBalanceMinorUnits else { return nil }
    return Decimal(balanceMinorUnits)
}

private func spendingClosingBalanceTotal(
    at day: Date,
    ledgerIds: Set<UUID>,
    txnsByLedger: [UUID?: [Transaction]],
    ledgerById: [UUID: Ledger],
    assetKinds: Set<LedgerKind>
) -> Decimal {
    var total: Decimal = 0
    for ledgerId in ledgerIds {
        guard let ledger = ledgerById[ledgerId] else { continue }
        if ledger.kind == .creditCard { continue }
        let isAsset = assetKinds.contains(ledger.kind)
        let cbMinorUnits = spendingEndOfDayClosingBalance(for: day, ledgerId: ledgerId, txnsByLedger: txnsByLedger)
            .map { Int64(NSDecimalNumber(decimal: $0).int64Value) }
        let balanceMinorUnits = cbMinorUnits ?? ledger.openingBalance ?? 0
        let balance = Decimal(balanceMinorUnits) / 100
        total += isAsset ? balance : -balance
    }
    return total
}

private func spendingResolveWindowStart(months: Int?, sortedDays: [Date], now: Date, calendar: Calendar) -> Date {
    guard let months,
          let cutoff = calendar.date(byAdding: .month, value: -months, to: now),
          let ws = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: cutoff))
    else { return sortedDays.first ?? now }
    return ws
}

private func spendingOpeningNetWorth(
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
        let balance = spendingLedgerOpeningBalance(ledger: ledger, isAsset: isAsset, txnsByLedger: txnsByLedger)
        total += isAsset ? balance : -balance
    }
    return total
}

private func spendingLedgerOpeningBalance(
    ledger: Ledger, isAsset: Bool, txnsByLedger: [UUID?: [Transaction]]
) -> Decimal {
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

private func spendingBuildLedgerTimeSeries(_ ctx: LedgerSeriesContext) -> LedgerBalanceTimeSeries {
    let statementDates: Set<Date> = Set((ctx.txnsByLedger[ctx.ledger.id] ?? [])
        .compactMap { txn -> Date? in
            guard txn.closingBalanceMinorUnits != nil else { return nil }
            return ctx.calendar.date(from: ctx.calendar.dateComponents([.year, .month, .day], from: txn.postedAt))
        })
    var running = spendingLedgerOpeningBalance(
        ledger: ctx.ledger, isAsset: true, txnsByLedger: ctx.txnsByLedger
    )
    for day in ctx.allDays where day < ctx.windowStart {
        running += ctx.deltaByDay[day] ?? 0
    }
    var points: [NetWorthPoint] = []
    var day = ctx.windowStart
    while day <= ctx.now {
        running += ctx.deltaByDay[day] ?? 0
        let cbMinorUnits: Decimal? = ctx.isClosingBalance && statementDates.contains(day)
            ? spendingEndOfDayClosingBalance(for: day, ledgerId: ctx.ledger.id, txnsByLedger: ctx.txnsByLedger)
            : nil
        let balance = cbMinorUnits ?? (running * 100)
        let minorUnits = Int64(NSDecimalNumber(decimal: balance).int64Value)
        points.append(NetWorthPoint(timestamp: day, netWorthMinorUnits: minorUnits))
        if let cb = cbMinorUnits { running = cb / 100 }
        guard let next = ctx.calendar.date(byAdding: .day, value: 1, to: day) else { break }
        day = next
    }
    return LedgerBalanceTimeSeries(
        ledgerId: ctx.ledger.id,
        ledgerName: ctx.ledger.displayName,
        ledgerKind: ctx.ledger.kind,
        points: points
    )
}

// MARK: - Actor

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

        let cbLedgerIds = spendingClosingBalanceLedgerIds(from: allTransactions)
        let ledgerById = Dictionary(uniqueKeysWithValues: allLedgers.map { ($0.id, $0) })
        let ledgerKindById = Dictionary(uniqueKeysWithValues: allLedgers.map { ($0.id, $0.kind) })

        let deltaLedgers = allLedgers.filter { !cbLedgerIds.contains($0.id) }
        let openingTotal = spendingOpeningNetWorth(
            assetKinds: assetKinds, liabilityKinds: liabilityKinds,
            ledgers: deltaLedgers, txnsByLedger: txnsByLedger
        )
        let deltaByDay = spendingBuildDeltaByDay(
            transactions: allTransactions, excludeLedgerIds: cbLedgerIds,
            ledgerKindById: ledgerKindById, assetKinds: assetKinds, calendar: calendar
        )
        let windowStart = spendingResolveWindowStart(
            months: months, sortedDays: deltaByDay.keys.sorted(), now: now, calendar: calendar
        )
        var running = openingTotal
        for day in deltaByDay.keys.sorted() where day < windowStart {
            running += deltaByDay[day] ?? 0
        }

        var points: [NetWorthPoint] = []
        var day = windowStart
        while day <= now {
            running += deltaByDay[day] ?? 0
            let cbTotal = spendingClosingBalanceTotal(
                at: day, ledgerIds: cbLedgerIds, txnsByLedger: txnsByLedger,
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
        let cbLedgerIds = spendingClosingBalanceLedgerIds(from: allTransactions)
        let bankAccountLedgers = allLedgers.filter { $0.kind == .bankAccount }
        let deltaByDayByLedger = spendingBuildDeltaByDayPerLedger(
            transactions: allTransactions, ledgers: bankAccountLedgers, calendar: calendar
        )
        let allDays = Set(deltaByDayByLedger.values.flatMap(\.keys)).sorted()
        let windowStart = spendingResolveWindowStart(months: months, sortedDays: allDays, now: now, calendar: calendar)
        return bankAccountLedgers.map { ledger in
            spendingBuildLedgerTimeSeries(LedgerSeriesContext(
                ledger: ledger,
                deltaByDay: deltaByDayByLedger[ledger.id] ?? [:],
                isClosingBalance: cbLedgerIds.contains(ledger.id),
                txnsByLedger: txnsByLedger,
                allDays: allDays,
                windowStart: windowStart,
                now: now,
                calendar: calendar
            ))
        }
    }
}
