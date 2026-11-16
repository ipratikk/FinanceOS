import FinanceCore
import FinanceOSAPI
import Foundation

@MainActor
enum GraphQLMappings {
    static func mapLedger(_ item: GetLedgersQuery.Data.Ledger) -> Ledger {
        let kind: FinanceCore.LedgerKind = item.kind.value == .creditCard ? .creditCard : .bankAccount
        return Ledger(
            id: item.id,
            bankId: item.bank.id,
            kind: kind,
            displayName: item.displayName,
            last4: item.last4 ?? "",
            closingBalance: Int64(item.balance.value)
        )
    }

    /// Full-fidelity ledger input for statement freshness. Keeps every LedgerKind (mapLedger collapses them).
    /// Returns nil for a kind this client build does not know, rather than guessing a kind.
    static func mapStatementInput(_ item: GetLedgersQuery.Data.Ledger) -> StatementLedgerInput? {
        guard let kind = item.kind.value.map(statementKind) else { return nil }
        return StatementLedgerInput(
            ledgerId: item.id,
            displayName: item.displayName,
            kind: kind,
            last4: item.last4 ?? "",
            bankName: item.bank.name,
            balanceMinor: Int64(item.balance.value),
            currencyCode: item.balance.currencyCode.rawValue,
            lastStatementDate: item.lastStatementAt.flatMap(parseTimestamp)
        )
    }

    private static func statementKind(_ kind: FinanceOSAPI.LedgerKind) -> FinanceCore.LedgerKind {
        switch kind {
        case .bankAccount: .bankAccount
        case .creditCard: .creditCard
        case .loan: .loan
        case .wallet: .wallet
        case .crypto: .crypto
        case .investment: .investment
        }
    }

    private static func parseTimestamp(_ string: String) -> Date? {
        iso8601Full.date(from: string) ?? iso8601Short.date(from: string)
    }

    static func mapBank(_ item: GetBanksQuery.Data.Bank) -> Bank {
        Bank(
            id: item.id,
            bank: Banks(rawValue: item.code.lowercased()) ?? .hdfc
        )
    }

    static func mapTransaction(_ item: GetTransactionsQuery.Data.Transaction) -> Transaction {
        let rawAmount = Int64(item.amount.value)
        let amountMinorUnits = abs(rawAmount)
        let transactionType: TransactionType = item.amount.value > 0 ? .debit : .credit
        return Transaction(
            id: item.id,
            ledgerId: item.ledger.id,
            postedAt: parseDate(item.date),
            description: item.narration,
            amountMinorUnits: amountMinorUnits,
            currencyCode: "INR",
            transactionType: transactionType,
            sourceFingerprint: item.sourceFingerprint,
            categoryId: item.category,
            merchantName: item.merchant
        )
    }

    static func mapMonthly(_ item: GetAnalyticsQuery.Data.Analytics.ByMonth) -> MonthlySpendingSummary {
        let components = item.month.split(separator: "-")
        var dc = DateComponents()
        dc.year = !components.isEmpty ? Int(components[0]) : nil
        dc.month = components.count > 1 ? Int(components[1]) : nil
        dc.day = 1
        let date = Calendar.current.date(from: dc) ?? Date()
        return MonthlySpendingSummary(
            month: date,
            totalDebit: Int64(item.spend.value),
            totalCredit: Int64(item.income.value)
        )
    }

    private static func parseDate(_ string: String) -> Date {
        if let date = iso8601Full.date(from: string) { return date }
        if let date = iso8601Short.date(from: string) { return date }
        return Date()
    }

    private static let iso8601Full: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601Short: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
