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

    // swiftlint:disable:next function_body_length
    public func normalize(_ rawDescription: String) -> MerchantCandidate {
        // HDFC internet banking bill payments: "IB BILLPAY DR-HDFCWI-{bin}XXXXXX{last4}"
        // Produce a clean name and flag as credit card payment.
        if let billpay = Self.parseBillPay(rawDescription) {
            return MerchantCandidate(MerchantCandidateInput(
                rawDescription: rawDescription,
                cleanedDescription: billpay,
                canonicalName: billpay,
                confidence: 0.92,
                source: .rule,
                categoryId: "fees"
            ))
        }

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

// MARK: - Bill Pay Detection

private extension MerchantNormalizer {
    /// Detects HDFC internet banking bill payment format and extracts card last 4.
    /// Format: "IB BILLPAY DR-HDFCWI-{anything}XXXXXX{last4}" or "IB BILLPAY DR-HDFCWI-{anything}xxxxxx{last4}"
    static func parseBillPay(_ raw: String) -> String? {
        let upper = raw.uppercased()
        guard upper.contains("BILLPAY") || upper.contains("BILL PAY") else { return nil }
        // Extract XXXXXX followed by 4 digits
        if let range = raw.range(of: "(?i)X{4,}(\\d{4})", options: .regularExpression) {
            let segment = String(raw[range])
            if let last4 = segment.range(of: "\\d{4}$", options: .regularExpression) {
                return "Card Payment ••••\(String(segment[last4]))"
            }
        }
        return "Credit Card Payment"
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
