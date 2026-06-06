import FinanceCore
import FinanceParsers
import Foundation

/// Transient UI state accumulated during the "add ledger" flow before a ``Ledger`` record is written.
/// Lives in a ViewModel; never persisted directly.
struct TargetCreationState: Identifiable, Equatable {
    let id = UUID()
    var customName: String = ""
    var nickname: String = ""
    var first4: String = ""
    var last4: String = ""
    /// Obfuscated card number captured from statement metadata (not stored in the DB).
    var encryptedCardNumber: String = ""
    var cardholderName: String = ""
    var selectedBank: Banks?
    /// Distinguishes card ledgers from account ledgers; drives which fields are shown in the form.
    var isCard: Bool = false
    var accountType: String = "savings"
    var cardType: CardNetwork = .other
    var cardProductId: String = ""
    var linkedLedgerId: UUID?

    init() {}

    /// Populates fields from a successfully parsed statement so the user sees pre-filled values.
    /// Only overwrites fields that the statement provides; manual overrides made earlier are preserved
    /// only if they come after this call.
    mutating func initializeFromStatement(_ statement: ParsedStatement) {
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
