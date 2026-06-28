import FinanceCore
import FinanceOSAPI
import Foundation

@MainActor
enum GraphQLMappings {
    static func mapLedger(_ item: GetLedgersQuery.Data.Ledger) -> Ledger {
        let kind: FinanceCore.LedgerKind = item.kind.value == .creditCard ? .creditCard : .bankAccount
        return Ledger(
            id: UUID(uuidString: item.id) ?? UUID(),
            bankId: UUID(uuidString: item.bank.id) ?? UUID(),
            kind: kind,
            displayName: item.displayName,
            last4: item.last4 ?? "",
            closingBalance: Int64(item.balance * 100)
        )
    }

    static func mapBank(_ item: GetBanksQuery.Data.Bank) -> Bank {
        Bank(
            id: UUID(uuidString: item.id) ?? UUID(),
            bank: Banks(rawValue: item.code.lowercased()) ?? .hdfc
        )
    }

    static func mapTransaction(_ item: GetTransactionsQuery.Data.Transaction) -> Transaction {
        let rawAmount = Int64(item.amount * 100)
        let amountMinorUnits = abs(rawAmount)
        let transactionType: TransactionType = item.amount < 0 ? .debit : .credit
        return Transaction(
            id: UUID(uuidString: item.id) ?? UUID(),
            ledgerId: UUID(uuidString: item.ledger.id),
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
            totalDebit: Int64(item.spend * 100),
            totalCredit: Int64(item.income * 100)
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
