import FinanceParsers
import Foundation

/// Transient UI state accumulated during the "add ledger" flow before a ``Ledger`` record is written.
/// Lives in a ViewModel; never persisted directly.
public struct TargetCreationState: Identifiable, Equatable {
    public let id = UUID()
    public var customName: String = ""
    public var nickname: String = ""
    public var first4: String = ""
    public var last4: String = ""
    /// Obfuscated card number captured from statement metadata (not stored in the DB).
    public var encryptedCardNumber: String = ""
    public var cardholderName: String = ""
    public var selectedBank: Banks?
    /// Distinguishes card ledgers from account ledgers; drives which fields are shown in the form.
    public var isCard: Bool = false
    public var accountType: String = "savings"
    public var cardType: CardNetwork = .other
    public var cardProductId: String = ""
    public var linkedLedgerId: UUID?

    public init() {}

    /// Populates fields from a successfully parsed statement so the user sees pre-filled values.
    /// Only overwrites fields that the statement provides; manual overrides made earlier are preserved
    /// only if they come after this call.
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
