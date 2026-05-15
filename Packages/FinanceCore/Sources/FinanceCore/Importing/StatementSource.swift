import FinanceParsers

public enum StatementSource: String, CaseIterable, Sendable, Hashable {
    case hdfcBank
    case hdfcCard
    case iciciBank
    case iciciCard
    case amex

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

    public var allowedFormats: [StatementFileFormat] {
        switch self {
        case .hdfcBank:
            return [.txt, .pdf]
        case .hdfcCard:
            return [.csv, .txt, .pdf]
        case .iciciBank:
            return [.pdf]
        case .iciciCard:
            return [.csv, .pdf]
        case .amex:
            return [.csv, .pdf]
        }
    }

    var bankName: String {
        switch self {
        case .hdfcBank, .hdfcCard:
            return "HDFC"
        case .iciciBank, .iciciCard:
            return "ICICI"
        case .amex:
            return "Amex"
        }
    }

    var sourceType: StatementSourceType {
        switch self {
        case .hdfcBank, .iciciBank:
            return .bankAccount
        case .hdfcCard, .iciciCard, .amex:
            return .creditCard
        }
    }
}
