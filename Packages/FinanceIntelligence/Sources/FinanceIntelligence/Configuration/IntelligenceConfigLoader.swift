import Foundation

/// Loads `IntelligenceConfig` from a JSON file, falling back to `defaultV1`.
public struct IntelligenceConfigLoader: Sendable {
    public init() {}

    /// Loads config from `fileURL` if it exists and is valid JSON; otherwise returns `defaultV1`.
    public func load(from fileURL: URL) -> IntelligenceConfig {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let config = try? JSONDecoder().decode(IntelligenceConfig.self, from: data)
        else {
            return .defaultV1
        }
        return config
    }
}
