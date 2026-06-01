import Foundation

/// Removes common narration artifacts from person names before entity resolution.
///
/// Handles:
/// - Repeated tokens: "Manasa Manasa Sharm" → "Manasa Sharm"
/// - Relational suffixes: "Lovish So Prem Kumar" → "Lovish" (S/O D/O W/O C/O)
/// - Gateway fragments embedded in names: drops tokens matching known VPA gateway suffixes
/// - All-caps normalization is handled separately by `PersonNameNormalizer`
public enum NameSanitizer {
    private static let relationalPrefixes: Set<String> = ["SO", "DO", "WO", "CO", "S/O", "D/O", "W/O", "C/O"]
    private static let gatewayTokens: Set<String> = ["@RZP", "@PTYS", "@PTYBL", "BDSI@", "@OKBIZAXIS"]

    /// Returns a cleaned version of `rawName` with narration artifacts removed.
    public static func sanitize(_ rawName: String) -> String {
        let upper = rawName.uppercased()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        // Truncate at first relational prefix (S/O, D/O, W/O, C/O)
        let truncated: [String] = if let relIdx = upper.firstIndex(where: { relationalPrefixes.contains($0) }),
                                     relIdx > 0 {
            Array(upper.prefix(relIdx))
        } else {
            upper
        }

        // Drop gateway fragment tokens
        let noGateway = truncated.filter { !gatewayTokens.contains($0) && !$0.hasPrefix("@") }

        // Remove consecutive duplicate tokens: ["MANASA", "MANASA", "SHARM"] → ["MANASA", "SHARM"]
        let deduped = noGateway.reduce(into: [String]()) { acc, token in
            if acc.last != token { acc.append(token) }
        }

        return deduped.joined(separator: " ")
    }

    /// True when `rawName` contains detectable artifacts (repeated tokens, relational suffixes, gateway fragments).
    public static func containsArtifacts(_ rawName: String) -> Bool {
        sanitize(rawName) != rawName.uppercased()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
