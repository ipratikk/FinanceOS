import Foundation

/// Payment network that processes a credit or debit card. The raw value is persisted in SQLite
/// via ``Ledger/cardType`` and must remain stable.
public enum CardNetwork: String, Codable, Sendable, CaseIterable {
    case visa
    case mastercard
    case amex
    case discover
    case diners
    /// National payment network for Indian-issued cards (NPCI).
    case rupay
    /// Fallback when the network cannot be determined from BIN lookup.
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

    /// Asset catalog name for the network logo; nil for networks without a bundled asset.
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
