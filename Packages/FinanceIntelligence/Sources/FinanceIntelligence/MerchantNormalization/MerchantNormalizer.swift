import Foundation

/// Orchestrates the merchant normalization pipeline:
///   1. Deterministic text cleaning
///   2. Alias table lookup
///   3. Fuzzy substring fallback
///   4. Raw description fallback
public struct MerchantNormalizer: Sendable {
    private let cleaner: MerchantTextCleaner
    private let aliasTable: MerchantAliasTable

    public init(aliasTable: MerchantAliasTable = .load()) {
        cleaner = MerchantTextCleaner()
        self.aliasTable = aliasTable
    }

    /// Resolves a `MerchantCandidate` from `rawDescription` by running the full normalization pipeline.
    /// Alias lookup is attempted on both the raw and cleaned description before falling back to fuzzy matching.
    public func normalize(_ rawDescription: String) -> MerchantCandidate {
        // For UPI/NEFT: extract the embedded merchant segment before generic cleaning
        let effectiveRaw = UPIDescriptionParser.merchantName(from: rawDescription) ?? rawDescription
        let cleaned = cleaner.clean(effectiveRaw)

        // Try alias on raw description first — handles cases where cleaning strips the merchant token
        let rawLower = rawDescription.lowercased()
        if let match = aliasTable.match(normalizedDescription: rawLower) {
            return MerchantCandidate(MerchantCandidateInput(
                rawDescription: rawDescription,
                cleanedDescription: cleaned,
                canonicalName: match.canonical,
                confidence: match.confidence,
                source: .alias,
                categoryId: match.categoryId
            ))
        }

        let normalized = cleaned.lowercased()
        if let match = aliasTable.match(normalizedDescription: normalized) {
            return MerchantCandidate(MerchantCandidateInput(
                rawDescription: rawDescription,
                cleanedDescription: cleaned,
                canonicalName: match.canonical,
                confidence: match.confidence,
                source: .alias,
                categoryId: match.categoryId
            ))
        }

        // Try fuzzy on cleaned text first, then raw (for cases where cleaning strips the merchant token)
        let fuzzyCandidate = fuzzyMatch(normalized: normalized) ?? fuzzyMatch(normalized: rawLower)
        if let fuzzy = fuzzyCandidate {
            return MerchantCandidate(MerchantCandidateInput(
                rawDescription: rawDescription,
                cleanedDescription: cleaned,
                canonicalName: fuzzy,
                confidence: 0.65,
                source: .fuzzy
            ))
        }

        let canonical = cleaned.isEmpty ? rawDescription : titleCase(cleaned)
        return MerchantCandidate(MerchantCandidateInput(
            rawDescription: rawDescription,
            cleanedDescription: cleaned,
            canonicalName: canonical,
            confidence: 0.5,
            source: .rule
        ))
    }
}

// MARK: - Fuzzy Fallback

private extension MerchantNormalizer {
    /// Simple deterministic similarity: known merchant tokens present in description.
    func fuzzyMatch(normalized: String) -> String? {
        let knownMerchants: [(tokens: [String], canonical: String)] = [
            (["amazon", "amzn"], "Amazon"),
            (["uber"], "Uber"),
            (["lyft"], "Lyft"),
            (["starbucks"], "Starbucks"),
            (["mcdonalds", "mcdonald"], "McDonald's"),
            (["spotify"], "Spotify"),
            (["netflix"], "Netflix"),
            (["apple"], "Apple"),
            (["google"], "Google"),
            (["swiggy"], "Swiggy"),
            (["zomato"], "Zomato"),
            (["doordash", "door dash"], "DoorDash"),
            (["target"], "Target"),
            (["walmart"], "Walmart"),
            (["whole foods", "wholefoods"], "Whole Foods"),
            (["airbnb"], "Airbnb")
        ]
        for entry in knownMerchants {
            for token in entry.tokens where normalized.contains(token) {
                return entry.canonical
            }
        }
        return nil
    }

    func titleCase(_ input: String) -> String {
        input.split(separator: " ")
            .map { word in
                let s = String(word)
                return s.prefix(1).uppercased() + s.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }
}
