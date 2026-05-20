import FinanceCore
import Foundation

/// Preview/test data for transactions.
public enum PreviewTransactions {
    /// Create a debit transaction.
    public static func debit(
        description: String = "Whole Foods Market",
        amountMinorUnits: Int64 = 6543
    ) -> Transaction {
        Transaction(
            id: UUID(),
            accountID: uuid("00000000-0000-0000-0000-000000000001"),
            postedAt: Date(timeIntervalSince1970: 1_747_000_000),
            description: description,
            amountMinorUnits: amountMinorUnits,
            currencyCode: "USD",
            transactionType: .debit
        )
    }

    /// Create a credit transaction.
    public static func credit(
        description: String = "Salary Deposit",
        amountMinorUnits: Int64 = 500_000
    ) -> Transaction {
        Transaction(
            id: UUID(),
            accountID: uuid("00000000-0000-0000-0000-000000000002"),
            postedAt: Date(timeIntervalSince1970: 1_747_000_000),
            description: description,
            amountMinorUnits: amountMinorUnits,
            currencyCode: "USD",
            transactionType: .credit
        )
    }

    /// Sample transactions for preview.
    public static var samples: [Transaction] {
        [
            debit(description: "Whole Foods Market", amountMinorUnits: 6543),
            debit(description: "Shell Gas Station", amountMinorUnits: 4215),
            debit(description: "Starbucks", amountMinorUnits: 625),
            debit(description: "Target", amountMinorUnits: 14567),
            credit(description: "Employer Deposit", amountMinorUnits: 500_000)
        ]
    }

    private static func uuid(_ value: String) -> UUID {
        guard let uuid = UUID(uuidString: value) else {
            fatalError("Invalid preview transaction UUID: \(value)")
        }
        return uuid
    }
}
