public enum StatementSource: String, CaseIterable, Sendable, Hashable {
    case hdfcBank
    case hdfcCard
    case iciciBank
    case iciciCard
    case axisBank
    case axisCard
    case sbiBank
    case sbiCard
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
        case .axisBank:
            return "Axis Bank"
        case .axisCard:
            return "Axis Card"
        case .sbiBank:
            return "SBI Bank"
        case .sbiCard:
            return "SBI Card"
        case .amex:
            return "American Express"
        }
    }

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
        case .axisBank:
            return [.csv]
        case .axisCard:
            return [.csv]
        case .sbiBank:
            return [.csv]
        case .sbiCard:
            return [.csv]
        case .amex:
            return [.csv]
        }
    }

    public var bankName: String {
        switch self {
        case .hdfcBank, .hdfcCard:
            return "HDFC"
        case .iciciBank, .iciciCard:
            return "ICICI"
        case .axisBank, .axisCard:
            return "Axis"
        case .sbiBank, .sbiCard:
            return "SBI"
        case .amex:
            return "Amex"
        }
    }

    public var sourceType: StatementSourceType {
        switch self {
        case .hdfcBank, .iciciBank, .axisBank, .sbiBank:
            return .bankAccount
        case .hdfcCard, .iciciCard, .axisCard, .sbiCard, .amex:
            return .creditCard
        }
    }
}
