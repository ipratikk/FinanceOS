import Foundation

struct MerchantAliasEntry: Codable {
    let canonical: String
    let patterns: [String]
    let categoryId: String?
}

struct MerchantAliasFile: Codable {
    let version: String
    let aliases: [MerchantAliasEntry]
}

/// Loads merchant alias table from bundled JSON and performs substring matching.
public struct MerchantAliasTable: Sendable {
    private let entries: [MerchantAliasEntry]
    public let version: String

    public static func load() -> MerchantAliasTable {
        guard let url = Bundle.module.url(forResource: "merchant_aliases", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(MerchantAliasFile.self, from: data)
        else {
            return MerchantAliasTable(entries: [], version: "0.0.0")
        }
        return MerchantAliasTable(entries: file.aliases, version: file.version)
    }

    /// Returns (canonical, confidence, categoryId?) for the first matching alias entry.
    public func match(normalizedDescription: String) -> (canonical: String, confidence: Double, categoryId: String?)? {
        let lower = normalizedDescription.lowercased()
        for entry in entries {
            for pattern in entry.patterns {
                if lower.contains(pattern.lowercased()) {
                    return (entry.canonical, 0.92, entry.categoryId)
                }
            }
        }
        return nil
    }
}
