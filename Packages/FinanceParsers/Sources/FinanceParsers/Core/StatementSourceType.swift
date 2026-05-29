import Foundation

/// Classifies the financial product type of a statement, used to route
/// transactions to the correct ledger and apply appropriate sign conventions.
public enum StatementSourceType: String, Sendable {
    case bankAccount = "Bank Account"
    case creditCard = "Credit Card"
    case investments = "Investments"

    /// SF Symbol name for display in import and account list UI.
    public var icon: String {
        switch self {
        case .bankAccount:
            return "building.columns.fill"
        case .creditCard:
            return "creditcard.fill"
        case .investments:
            return "banknote.fill"
        }
    }
}
