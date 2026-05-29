import Foundation

/// Classifies the financial instrument a ``Ledger`` represents.
/// The raw value is persisted in SQLite and must remain stable across releases.
public enum LedgerKind: String, Codable, Sendable, CaseIterable, Hashable {
    case bankAccount
    case creditCard
    case loan
    case wallet
    /// Cryptocurrency wallet; tracked but not used by any current parser.
    case crypto
    case investment

    /// Human-readable label used in UI pickers and list headers.
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

    /// SF Symbol name representing this ledger kind in the UI.
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
