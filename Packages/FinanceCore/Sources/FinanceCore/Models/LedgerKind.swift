import Foundation

public enum LedgerKind: String, Codable, Sendable, CaseIterable, Hashable {
    case bankAccount = "bankAccount"
    case creditCard = "creditCard"
    case loan = "loan"
    case wallet = "wallet"
    case crypto = "crypto"
    case investment = "investment"

    public var displayName: String {
        switch self {
        case .bankAccount:
            return "Bank Account"
        case .creditCard:
            return "Credit Card"
        case .loan:
            return "Loan"
        case .wallet:
            return "Wallet"
        case .crypto:
            return "Crypto"
        case .investment:
            return "Investment"
        }
    }
}
