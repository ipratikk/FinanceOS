import FinanceCore
import Foundation

/// Preview/test data for transactions.
public enum PreviewTransactions {
    /// Create a debit transaction.
    public static func debit(
        merchant: String = "Whole Foods Market",
        amount: Double = 65.43,
        category: String = "Groceries"
    ) -> Transaction {
        Transaction(
            id: UUID(),
            accountID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            merchant: merchant,
            amount: amount,
            currency: "USD",
            category: category,
            transactionDate: Date(timeIntervalSince1970: 1_747_000_000),
            createdAt: Date(timeIntervalSince1970: 1_747_000_000),
            isRecurring: false,
            notes: nil
        )
    }

    /// Create a credit transaction.
    public static func credit(
        merchant: String = "Salary Deposit",
        amount: Double = 5000.00,
        category: String = "Income"
    ) -> Transaction {
        Transaction(
            id: UUID(),
            accountID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            merchant: merchant,
            amount: amount,
            currency: "USD",
            category: category,
            transactionDate: Date(timeIntervalSince1970: 1_747_000_000),
            createdAt: Date(timeIntervalSince1970: 1_747_000_000),
            isRecurring: true,
            notes: "Monthly salary"
        )
    }

    /// Sample transactions for preview.
    public static var samples: [Transaction] {
        [
            debit(merchant: "Whole Foods Market", amount: 65.43, category: "Groceries"),
            debit(merchant: "Shell Gas Station", amount: 42.15, category: "Gas"),
            debit(merchant: "Starbucks", amount: 6.25, category: "Coffee"),
            debit(merchant: "Target", amount: 145.67, category: "Shopping"),
            credit(merchant: "Employer Deposit", amount: 5000.00, category: "Income")
        ]
    }
}
