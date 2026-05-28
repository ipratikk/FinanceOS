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

public struct AliasMatch: Sendable {
    public let canonical: String
    public let confidence: Double
    public let categoryId: String?
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
