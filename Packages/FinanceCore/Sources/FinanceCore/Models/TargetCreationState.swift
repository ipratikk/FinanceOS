import FinanceParsers
import Foundation

public struct TargetCreationState: Identifiable, Equatable {
    public let id = UUID()
    public var customName: String = ""
    public var nickname: String = ""
    public var first4: String = ""
    public var last4: String = ""
    public var encryptedCardNumber: String = ""
    public var cardholderName: String = ""
    public var selectedBank: Banks?
    public var isCard: Bool = false
    public var accountType: String = "savings"
    public var cardType: CardNetwork = .other
    public var cardProductId: String = ""
    public var linkedLedgerId: UUID?

    public init() {}

    public mutating func initializeFromStatement(_ statement: ParsedStatement) {
        last4 = isCard ? (statement.cardLast4 ?? "") : (statement.accountLast4 ?? "")
        encryptedCardNumber = isCard ? (statement.metadata?.fullAccountNumber ?? "") : ""

        cardholderName = statement.metadata?.customerName ?? ""

        if isCard {
            cardType = CardNetwork(rawValue: statement.metadata?.cardType ?? "") ?? .other
        } else {
            accountType = (statement.metadata?.accountType ?? "savings").lowercased()
        }

        let displayName = statement.accountName.isEmpty ? statement.bankName : statement.accountName
        customName = displayName
    }
}
