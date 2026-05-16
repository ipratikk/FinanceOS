import FinanceParsers
import Foundation

public struct TargetCreationState {
    public var customName: String = ""
    public var nickname: String = ""
    public var last4: String = ""
    public var ownerName: String = ""
    public var selectedBankID: UUID?
    public var isCard: Bool = false
    public var accountType: String = "savings"
    public var cardType: String = "other"

    public init() {}

    public mutating func initializeFromStatement(_ statement: ParsedStatement) {
        last4 = isCard ? (statement.cardLast4 ?? "") : (statement.accountLast4 ?? "")

        ownerName = statement.metadata?.customerName ?? ""

        if isCard {
            cardType = statement.metadata?.cardType ?? "other"
        } else {
            accountType = statement.metadata?.accountType ?? "savings"
        }

        let displayName = statement.accountName.isEmpty ? statement.bankName : statement.accountName
        customName = !last4.isEmpty
            ? "\(displayName) •••• \(last4)"
            : displayName
    }
}
