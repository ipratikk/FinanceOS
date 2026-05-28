import FinanceCore
import Foundation

/// In-memory mock LedgerRepository for snapshot/unit tests.
public final class MockLedgerRepository: LedgerRepository, @unchecked Sendable {
    public var ledgers: [Ledger]

    public init(ledgers: [Ledger] = PreviewLedgers.all) {
        self.ledgers = ledgers
    }

    public func fetchLedgers() async throws -> [Ledger] {
        ledgers
    }

    public func fetchLedgers(bankId: UUID) async throws -> [Ledger] {
        ledgers.filter { $0.bankId == bankId }
    }

    public func fetchLedgers(kind: LedgerKind) async throws -> [Ledger] {
        ledgers.filter { $0.kind == kind }
    }

    public func fetchLedgers(bankId: UUID, kind: LedgerKind) async throws -> [Ledger] {
        ledgers.filter { $0.bankId == bankId && $0.kind == kind }
    }

    public func fetchLedger(id: UUID) async throws -> Ledger? {
        ledgers.first { $0.id == id }
    }

    public func insert(_ ledger: Ledger) async throws {
        ledgers.append(ledger)
    }

    public func update(_ ledger: Ledger) async throws {
        if let idx = ledgers.firstIndex(where: { $0.id == ledger.id }) {
            ledgers[idx] = ledger
        }
    }

    public func updateClosingBalance(id: UUID, balance: Int64, asOf: Date) async throws {
        if let idx = ledgers.firstIndex(where: { $0.id == id }) {
            let updated = ledgers[idx]
            ledgers[idx] = Ledger(
                id: updated.id,
                bankId: updated.bankId,
                kind: updated.kind,
                displayName: updated.displayName,
                last4: updated.last4,
                nickname: updated.nickname,
                ownerName: updated.ownerName,
                createdAt: updated.createdAt,
                accountType: updated.accountType,
                cardType: updated.cardType,
                cardProductId: updated.cardProductId,
                bin: updated.bin,
                linkedLedgerId: updated.linkedLedgerId,
                isArchived: updated.isArchived,
                openingBalance: updated.openingBalance,
                closingBalance: balance,
                closingBalanceAsOf: asOf
            )
        }
    }

    public func updateOpeningBalance(id: UUID, balance: Int64) async throws {
        if let idx = ledgers.firstIndex(where: { $0.id == id }) {
            let updated = ledgers[idx]
            ledgers[idx] = Ledger(
                id: updated.id,
                bankId: updated.bankId,
                kind: updated.kind,
                displayName: updated.displayName,
                last4: updated.last4,
                nickname: updated.nickname,
                ownerName: updated.ownerName,
                createdAt: updated.createdAt,
                accountType: updated.accountType,
                cardType: updated.cardType,
                cardProductId: updated.cardProductId,
                bin: updated.bin,
                linkedLedgerId: updated.linkedLedgerId,
                isArchived: updated.isArchived,
                openingBalance: balance,
                closingBalance: updated.closingBalance,
                closingBalanceAsOf: updated.closingBalanceAsOf
            )
        }
    }

    public func archive(id: UUID) async throws {
        // No-op for snapshots
    }

    public func delete(id: UUID) async throws {
        ledgers.removeAll { $0.id == id }
    }
}

/// In-memory mock BankRepository.
public final class MockBankRepository: BankRepository, @unchecked Sendable {
    public var banks: [Bank]

    public init(banks: [Bank] = PreviewBanks.all) {
        self.banks = banks
    }

    public func fetchBanks() async throws -> [Bank] {
        banks
    }

    public func insert(_ bank: Bank) async throws {
        banks.append(bank)
    }

    public func update(_ bank: Bank) async throws {
        if let idx = banks.firstIndex(where: { $0.id == bank.id }) {
            banks[idx] = bank
        }
    }

    public func delete(id: UUID) async throws {
        banks.removeAll { $0.id == id }
    }

    public func deleteAll() async throws {
        banks.removeAll()
    }
}

/// In-memory mock TransactionRepository.
public final class MockTransactionRepository: TransactionRepository, @unchecked Sendable {
    public var transactions: [Transaction]

    public init(transactions: [Transaction] = PreviewTransactions.samples) {
        self.transactions = transactions
    }

    public func fetchTransactions() async throws -> [Transaction] {
        transactions
    }

    public func fetchTransactionsForLedger(_ ledgerID: UUID) async throws -> [Transaction] {
        transactions.filter { $0.ledgerId == ledgerID }
    }

    public func fetchTransactionsForAccount(_ accountID: UUID) async throws -> [Transaction] {
        transactions.filter { $0.accountID == accountID }
    }

    public func fetchTransactionsForCard(_ cardID: UUID) async throws -> [Transaction] {
        transactions.filter { $0.cardID == cardID }
    }

    public func insertTransactions(_ transactions: [Transaction]) async throws -> ImportResult {
        self.transactions.append(contentsOf: transactions)
        return ImportResult(inserted: transactions.count, skipped: 0)
    }

    public func delete(id: UUID) async throws {
        transactions.removeAll { $0.id == id }
    }

    public func migrateTransactions(fromCard cardID: UUID, toAccount accountID: UUID) async throws {
        // No-op for snapshots
    }

    public func migrateTransactions(fromAccount accountID: UUID, toCard cardID: UUID) async throws {
        // No-op for snapshots
    }

    public func updateIntelligence(id: UUID, categoryId: String?, merchantName: String?) async throws {
        if let idx = transactions.firstIndex(where: { $0.id == id }) {
            let t = transactions[idx]
            transactions[idx] = Transaction(
                id: t.id, ledgerId: t.ledgerId, accountID: t.accountID, cardID: t.cardID,
                postedAt: t.postedAt, description: t.description,
                amountMinorUnits: t.amountMinorUnits, currencyCode: t.currencyCode,
                transactionType: t.transactionType, sourceFingerprint: t.sourceFingerprint,
                categoryId: categoryId, merchantName: merchantName
            )
        }
    }
}

/// Mock SpendingService for snapshot tests.
public final class MockSpendingService: SpendingServiceProtocol, @unchecked Sendable {
    public var summaries: [MonthlySpendingSummary]
    public var totals: SpendingTotals
    public var recent: [Transaction]
    public var series: [NetWorthPoint]

    public init(
        summaries: [MonthlySpendingSummary] = PreviewSpendingData.monthlySummaries,
        totals: SpendingTotals = PreviewSpendingData.currentTotals,
        recent: [Transaction] = PreviewTransactions.samples,
        series: [NetWorthPoint] = PreviewSpendingData.netWorthSeries
    ) {
        self.summaries = summaries
        self.totals = totals
        self.recent = recent
        self.series = series
    }

    public func monthlySummary(months: Int?) async throws -> [MonthlySpendingSummary] {
        summaries
    }

    public func currentMonthTotals() async throws -> SpendingTotals {
        totals
    }

    public func recentTransactions(limit: Int) async throws -> [Transaction] {
        Array(recent.prefix(limit))
    }

    public func netWorthTimeSeries(months: Int?) async throws -> [NetWorthPoint] {
        series
    }
}
