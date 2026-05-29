import Foundation

/// Identifies how the canonical merchant name was resolved from the raw bank description.
public enum MerchantResolutionSource: String, Codable, Sendable {
    /// Resolved by deterministic text-cleaning rules (title-case of cleaned string).
    case rule
    /// Matched against the bundled `merchant_aliases.json` table.
    case alias
    /// Matched using a simple substring token heuristic against known merchant names.
    case fuzzy
    /// Resolved by an ML model (reserved for future use).
    case model
    /// No resolution succeeded; raw description is used as-is.
    case fallback
}

/// Mutable input bag used to construct a `MerchantCandidate`. Not exposed outside the module.
public struct MerchantCandidateInput: Sendable {
    /// Unmodified description string from the bank statement.
    public let rawDescription: String
    /// Description after processor prefixes, transaction IDs, and URL noise are stripped.
    public let cleanedDescription: String
    /// Normalized display name (e.g. `"Swiggy"`, `"Amazon"`).
    public let canonicalName: String
    /// Resolution confidence in [0, 1].
    public let confidence: Double
    /// Which step of the normalization pipeline produced this candidate.
    public let source: MerchantResolutionSource
    /// Known alternate names for this merchant (populated from alias table).
    public let aliases: [String]
    /// Category hint from the alias table. Nil when resolved by rules or fuzzy match.
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

/// The resolved merchant identity for a transaction, produced by `MerchantNormalizer`.
/// `confidence` is in [0, 1]; alias matches score ~0.92, fuzzy ~0.65, raw fallback ~0.5.
public struct MerchantCandidate: Sendable, Codable {
    /// Unmodified description string from the bank statement.
    public let rawDescription: String
    /// Description after preprocessing strips noise (IDs, processor prefixes, city/state).
    public let cleanedDescription: String
    /// Normalized display name resolved by the normalization pipeline.
    public let canonicalName: String
    /// Resolution confidence in [0, 1].
    public let confidence: Double
    /// Which normalization step produced this candidate.
    public let source: MerchantResolutionSource
    /// Alternate known names for this merchant from the alias table.
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

    /// Returns a low-confidence candidate using the raw description when no normalization succeeds.
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
