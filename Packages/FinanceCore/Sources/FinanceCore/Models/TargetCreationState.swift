import FinanceParsers
import Foundation

public struct TargetCreationState: Identifiable {
    public let id = UUID()
    public var customName: String = ""
    public var nickname: String = ""
    public var last4: String = ""
    public var maskedCardNumber: String = ""
    public var ownerName: String = ""
    public var selectedBankID: UUID?
    public var isCard: Bool = false
    public var accountType: String = "savings"
    public var cardType: String = "other"

    public init() {}

    public mutating func initializeFromStatement(_ statement: ParsedStatement) {
        last4 = isCard ? (statement.cardLast4 ?? "") : (statement.accountLast4 ?? "")
        maskedCardNumber = isCard ? (statement.metadata?.fullAccountNumber ?? "") : ""

        ownerName = statement.metadata?.customerName ?? ""

        if isCard {
            cardType = statement.metadata?.cardType ?? "other"
        } else {
            accountType = statement.metadata?.accountType ?? "savings"
        }

        let displayName = statement.accountName.isEmpty ? statement.bankName : statement.accountName
        customName = displayName
    }
}
