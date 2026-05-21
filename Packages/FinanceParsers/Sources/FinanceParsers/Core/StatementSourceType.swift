import Foundation

public enum StatementSourceType: String, Sendable {
    case bankAccount = "Bank Account"
    case creditCard = "Credit Card"
    case investments = "Investments"

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
