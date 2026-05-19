import Foundation

public enum LedgerKind: String, Codable, Sendable, CaseIterable, Hashable {
    case bankAccount
    case creditCard
    case loan
    case wallet
    case crypto
    case investment

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

    public var symbol: String {
        switch self {
        case .bankAccount:
            return "building.2"
        case .creditCard:
            return "creditcard"
        case .loan:
            return "dollarsign.circle"
        case .wallet:
            return "wallet.pass"
        case .crypto:
            return "bitcoinsign"
        case .investment:
            return "chart.pie"
        }
    }
}
