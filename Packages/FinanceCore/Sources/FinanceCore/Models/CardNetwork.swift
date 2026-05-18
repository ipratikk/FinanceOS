import Foundation

public enum CardNetwork: String, Codable, Sendable, CaseIterable {
    case visa
    case mastercard
    case amex
    case discover
    case diners
    case rupay
    case other

    public var displayName: String {
        switch self {
        case .visa: "Visa"
        case .mastercard: "Mastercard"
        case .amex: "American Express"
        case .discover: "Discover"
        case .diners: "Diners Club"
        case .rupay: "RuPay"
        case .other: "Other"
        }
    }

    public var logoAssetName: String? {
        switch self {
        case .visa: "visa"
        case .mastercard: "mastercard"
        case .amex: "amex-symbol"
        case .diners: "diners"
        case .rupay: "rupay"
        case .discover, .other: nil
        }
    }

    public var symbolAssetName: String? {
        logoAssetName
    }
}
