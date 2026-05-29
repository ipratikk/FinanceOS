import Foundation

/// Static catalogue entry describing a specific card product (e.g. HDFC Regalia, ICICI Amazon Pay).
/// Loaded from ``CardDatabase`` and matched against a ``Ledger`` via BIN ranges or `cardProductId`.
public struct CardMetadata: Codable, Identifiable, Equatable, Sendable {
    /// Stable string identifier matching ``Ledger/cardProductId``.
    public let id: String
    public let issuer: String
    public let name: String
    public let cardType: CardNetwork
    /// Product tier or funding type: "credit", "debit", "signature", "infinite", etc.
    public let variant: String
    /// One or more BIN ranges used to auto-detect the card product from the first 6 digits.
    public let binRanges: [BINRange]
    public let imageURL: String?
    public let details: CardDetails
    /// False for cards in the catalogue that are not yet fully supported for import.
    public let isSupported: Bool

    /// Inclusive numeric range over the first 6 digits of a card number (BIN).
    public struct BINRange: Codable, Equatable, Sendable {
        public let start: String
        public let end: String

        /// Returns true when the first 6 digits of `bin` fall within this range.
        public func matches(_ bin: String) -> Bool {
            guard bin.count >= 6 else { return false }
            let binNum = Int(bin.prefix(6)) ?? 0
            guard let startNum = Int(start), let endNum = Int(end) else { return false }
            return (startNum ... endNum).contains(binNum)
        }
    }

    /// Marketing and eligibility copy surfaced in the card detail view.
    public struct CardDetails: Codable, Equatable, Sendable {
        public let description: String
        public let features: [String]
        public let annualFee: String?
        public let eligibility: String?

        public init(
            description: String,
            features: [String] = [],
            annualFee: String? = nil,
            eligibility: String? = nil
        ) {
            self.description = description
            self.features = features
            self.annualFee = annualFee
            self.eligibility = eligibility
        }
    }

    public init(
        id: String,
        issuer: String,
        name: String,
        cardType: CardNetwork,
        variant: String,
        binRanges: [BINRange],
        imageURL: String? = nil,
        details: CardDetails,
        isSupported: Bool = true
    ) {
        self.id = id
        self.issuer = issuer
        self.name = name
        self.cardType = cardType
        self.variant = variant
        self.binRanges = binRanges
        self.imageURL = imageURL
        self.details = details
        self.isSupported = isSupported
    }

    /// Returns true if `bin` falls within any of this card's BIN ranges.
    public func matches(_ bin: String) -> Bool {
        binRanges.contains { $0.matches(bin) }
    }
}
