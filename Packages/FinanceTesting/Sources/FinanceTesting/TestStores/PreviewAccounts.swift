import FinanceCore
import Foundation

/// Preview/test data for accounts.
public enum PreviewAccounts {
    /// Create a preview checking account.
    public static func checking() -> Account {
        Account(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            accountName: "Checking",
            accountType: .checking,
            bankName: "Chase",
            accountNumber: "****1234",
            currencyCode: "USD",
            currentBalance: 5234.56,
            createdAt: Date(timeIntervalSince1970: 1_740_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_747_000_000)
        )
    }

    /// Create a preview savings account.
    public static func savings() -> Account {
        Account(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            accountName: "Savings",
            accountType: .savings,
            bankName: "Chase",
            accountNumber: "****5678",
            currencyCode: "USD",
            currentBalance: 25000.00,
            createdAt: Date(timeIntervalSince1970: 1_740_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_747_000_000)
        )
    }

    /// Create preview credit card.
    public static func creditCard() -> Account {
        Account(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            accountName: "Amex Premium",
            accountType: .creditCard,
            bankName: "American Express",
            accountNumber: "****9999",
            currencyCode: "USD",
            currentBalance: -2450.00,
            createdAt: Date(timeIntervalSince1970: 1_740_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_747_000_000)
        )
    }

    /// Collection of accounts for preview.
    public static var all: [Account] {
        [checking(), savings(), creditCard()]
    }
}
