/// Identifies a specific bank-product combination that the parser pipeline supports.
/// Each case maps to exactly one `bankName`, `sourceType`, and set of `allowedFormats`.
public enum StatementSource: String, CaseIterable, Sendable, Hashable {
    case hdfcBank
    case hdfcCard
    case iciciBank
    case iciciCard
    case amex

    /// User-facing label shown in import UI.
    public var displayName: String {
        switch self {
        case .hdfcBank:
            return "HDFC Bank"
        case .hdfcCard:
            return "HDFC Card"
        case .iciciBank:
            return "ICICI Bank"
        case .iciciCard:
            return "ICICI Card"
        case .amex:
            return "American Express"
        }
    }

    /// File formats the institution's export tool actually produces for this product.
    public var allowedFormats: [StatementFileFormat] {
        switch self {
        case .hdfcBank:
            return [.txt]
        case .hdfcCard:
            return [.csv, .txt]
        case .iciciBank:
            return [.csv]
        case .iciciCard:
            return [.csv]
        case .amex:
            return [.csv]
        }
    }

    /// Short institution identifier shared between bank and card products, e.g. `"HDFC"`.
    public var bankName: String {
        switch self {
        case .hdfcBank, .hdfcCard:
            return "HDFC"
        case .iciciBank, .iciciCard:
            return "ICICI"
        case .amex:
            return "Amex"
        }
    }

    /// Whether this source represents a bank account or credit card.
    public var sourceType: StatementSourceType {
        switch self {
        case .hdfcBank, .iciciBank:
            return .bankAccount
        case .hdfcCard, .iciciCard, .amex:
            return .creditCard
        }
    }
}
