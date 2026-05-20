import FinanceCore
import Foundation

/// Preview/test data for ledgers (accounts and cards).
public enum PreviewLedgers {
    /// Standard bank UUID for all preview ledgers.
    private static let bankId = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!

    /// Create a preview checking account.
    public static func checking() -> Ledger {
        Ledger(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            bankId: bankId,
            kind: .bankAccount,
            displayName: "Chase Checking",
            last4: "1234",
            nickname: "Checking",
            ownerName: "John Doe",
            createdAt: Date(timeIntervalSince1970: 1_740_000_000),
            accountType: "checking"
        )
    }

    /// Create a preview savings account.
    public static func savings() -> Ledger {
        Ledger(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            bankId: bankId,
            kind: .bankAccount,
            displayName: "Chase Savings",
            last4: "5678",
            nickname: "Savings",
            ownerName: "John Doe",
            createdAt: Date(timeIntervalSince1970: 1_740_000_000),
            accountType: "savings"
        )
    }

    /// Create a preview credit card.
    public static func creditCard() -> Ledger {
        Ledger(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            bankId: bankId,
            kind: .creditCard,
            displayName: "Amex Premium",
            last4: "9999",
            nickname: "Amex",
            ownerName: "John Doe",
            createdAt: Date(timeIntervalSince1970: 1_740_000_000),
            cardType: .amex,
            cardProductId: "Premium Rewards",
            bin: "378282"
        )
    }

    /// Collection of ledgers for preview.
    public static var all: [Ledger] {
        [checking(), savings(), creditCard()]
    }
}
