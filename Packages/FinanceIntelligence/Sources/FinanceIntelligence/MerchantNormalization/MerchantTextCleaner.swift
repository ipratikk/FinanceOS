import Foundation

/// Deterministic preprocessing pipeline that strips noise from raw bank descriptions.
/// Always returns a human-readable cleaned string; does NOT lowercase (use lowercased() for matching).
public struct MerchantTextCleaner: Sendable {
    public init() {}

    public func clean(_ raw: String) -> String {
        var result = raw
        result = stripProcessorPrefixes(result)
        result = stripTransactionIDs(result)
        result = stripURLs(result)
        result = stripCityStateNoise(result)
        result = normalizeWhitespace(result)
        return result.trimmingCharacters(in: .whitespaces)
    }

    public func normalizedForMatching(_ raw: String) -> String {
        clean(raw).lowercased()
    }
}

// MARK: - Cleaning Steps

private extension MerchantTextCleaner {
    func stripProcessorPrefixes(_ input: String) -> String {
        let prefixes = [
            "SQ *", "SQ*",
            "TST* ", "TST*",
            "PAYPAL *", "PAYPAL*",
            "STRIPE *", "STRIPE*",
            "APPLE.COM/BILL",
            "AMZN MKTP US*",
            "AMZN*"
        ]
        var result = input
        if let prefix = prefixes.first(where: { result.uppercased().hasPrefix($0) }) {
            result = String(result.dropFirst(prefix.count))
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    func stripTransactionIDs(_ input: String) -> String {
        // Remove pure-numeric sequences of 4+ digits (transaction/reference IDs)
        let pattern = #"\s*#?\d{4,}\s*"#
        return replace(pattern: pattern, in: input, with: " ")
    }

    func stripURLs(_ input: String) -> String {
        // Requires leading whitespace — avoids stripping standalone merchant names like "NETFLIX.COM".
        // Multi-part domains (HELP.UBER.COM) are matched via repeating (?:\w+\.)+ groups.
        let pattern = #"\s+(?:\w+\.)+(?:com|co|net|org|io|app)(?:/\S*)?"#
        return replace(pattern: pattern, in: input, with: "", options: .caseInsensitive)
    }

    func stripCityStateNoise(_ input: String) -> String {
        // Strips trailing "WORD STATE" (e.g. "FRANCISCO CA") — one city word + 2-letter state code.
        // Conservative: only strips last city word to avoid eating merchant names.
        let pattern = #"\s+[A-Z][A-Z]+\s+[A-Z]{2}\s*$"#
        return replace(pattern: pattern, in: input, with: "")
    }

    func normalizeWhitespace(_ input: String) -> String {
        input.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    func replace(
        pattern: String,
        in input: String,
        with replacement: String,
        options: NSRegularExpression.Options = []
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return input }
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, range: range, withTemplate: replacement)
    }
}
