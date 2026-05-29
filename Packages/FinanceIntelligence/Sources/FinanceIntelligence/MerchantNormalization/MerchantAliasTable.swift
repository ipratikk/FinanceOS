import Foundation

/// A single entry in `merchant_aliases.json` mapping known patterns to a canonical name.
struct MerchantAliasEntry: Codable {
    /// The canonical merchant display name (e.g. `"Swiggy"`).
    let canonical: String
    /// Lowercase substrings that trigger this entry when found in the normalized description.
    let patterns: [String]
    /// Optional category hint used to skip ML inference when the alias is unambiguous.
    let categoryId: String?
}

/// Top-level JSON structure for `merchant_aliases.json`.
struct MerchantAliasFile: Codable {
    /// Semantic version of the alias table.
    let version: String
    /// All alias entries in the file.
    let aliases: [MerchantAliasEntry]
}

/// The result of a successful alias-table lookup.
public struct AliasMatch: Sendable {
    /// Canonical merchant display name (e.g. `"Netflix"`).
    public let canonical: String
    /// Fixed confidence for alias matches (~0.92).
    public let confidence: Double
    /// Category hint from the alias entry. Nil when none is specified.
    public let categoryId: String?
}

/// Loads merchant alias table from bundled JSON and performs substring matching.
public struct MerchantAliasTable: Sendable {
    private let entries: [MerchantAliasEntry]
    public let version: String

    /// Loads the alias table from the module bundle. Returns an empty table when the resource is missing.
    public static func load() -> MerchantAliasTable {
        guard let url = Bundle.module.url(forResource: "merchant_aliases", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(MerchantAliasFile.self, from: data)
        else {
            return MerchantAliasTable(entries: [], version: "0.0.0")
        }
        return MerchantAliasTable(entries: file.aliases, version: file.version)
    }

    /// Returns the first alias entry whose patterns appear as a substring in `normalizedDescription`.
    public func match(normalizedDescription: String) -> AliasMatch? {
        let lower = normalizedDescription.lowercased()
        for entry in entries {
            for pattern in entry.patterns where lower.contains(pattern.lowercased()) {
                return AliasMatch(canonical: entry.canonical, confidence: 0.92, categoryId: entry.categoryId)
            }
        }
        return nil
    }
}
