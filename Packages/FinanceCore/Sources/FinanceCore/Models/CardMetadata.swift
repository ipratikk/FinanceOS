import Foundation

public struct CardMetadata: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let issuer: String
    public let name: String
    public let cardType: String // visa, mastercard, amex, rupay, etc
    public let variant: String // credit, debit, signature, infinite, etc
    public let binRanges: [BINRange]
    public let imageURL: String?
    public let details: CardDetails
    public let isSupported: Bool

    public struct BINRange: Codable, Equatable, Sendable {
        public let start: String
        public let end: String

        public func matches(_ bin: String) -> Bool {
            guard bin.count >= 6 else { return false }
            let binNum = Int(bin.prefix(6)) ?? 0
            guard let startNum = Int(start), let endNum = Int(end) else { return false }
            return (startNum ... endNum).contains(binNum)
        }
    }

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
        cardType: String,
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

    public func matches(_ bin: String) -> Bool {
        binRanges.contains { $0.matches(bin) }
    }
}
