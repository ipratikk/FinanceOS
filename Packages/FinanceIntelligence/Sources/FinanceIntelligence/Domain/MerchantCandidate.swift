import Foundation

public enum MerchantResolutionSource: String, Codable, Sendable {
    case rule
    case alias
    case fuzzy
    case model
    case fallback
}

public struct MerchantCandidateInput: Sendable {
    public let rawDescription: String
    public let cleanedDescription: String
    public let canonicalName: String
    public let confidence: Double
    public let source: MerchantResolutionSource
    public let aliases: [String]
    public let categoryId: String?

    public init(
        rawDescription: String,
        cleanedDescription: String,
        canonicalName: String,
        confidence: Double,
        source: MerchantResolutionSource,
        aliases: [String] = [],
        categoryId: String? = nil
    ) {
        self.rawDescription = rawDescription
        self.cleanedDescription = cleanedDescription
        self.canonicalName = canonicalName
        self.confidence = confidence
        self.source = source
        self.aliases = aliases
        self.categoryId = categoryId
    }
}

public struct MerchantCandidate: Sendable, Codable {
    public let rawDescription: String
    public let cleanedDescription: String
    public let canonicalName: String
    public let confidence: Double
    public let source: MerchantResolutionSource
    public let aliases: [String]
    /// Category hint derived from the alias table. Nil when resolved by rules or fuzzy match.
    public let categoryId: String?

    init(_ input: MerchantCandidateInput) {
        rawDescription = input.rawDescription
        cleanedDescription = input.cleanedDescription
        canonicalName = input.canonicalName
        confidence = input.confidence
        source = input.source
        aliases = input.aliases
        categoryId = input.categoryId
    }

    static func fallback(rawDescription: String) -> MerchantCandidate {
        MerchantCandidate(MerchantCandidateInput(
            rawDescription: rawDescription,
            cleanedDescription: rawDescription,
            canonicalName: rawDescription,
            confidence: 0.3,
            source: .fallback
        ))
    }
}
