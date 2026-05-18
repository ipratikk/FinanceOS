import SwiftUI

/// Thread-safe image cache to eliminate AsyncImage memory churn.
/// Caches loaded images to prevent repeated downloads/loads.
public actor ImageCache {
    public static let shared = ImageCache()

    private var cache: [URL: Image] = [:]

    // MARK: - Public API

    public func image(for url: URL?) -> Image? {
        guard let url else { return nil }
        return cache[url]
    }

    public func setImage(_ image: Image, for url: URL) {
        cache[url] = image
    }

    public func removeImage(for url: URL) {
        cache.removeValue(forKey: url)
    }

    public func clearCache() {
        cache.removeAll()
    }

    // MARK: - Cache Statistics

    public var cacheSize: Int {
        cache.count
    }

    public func cacheStats() -> [String: Any] {
        ["cacheSize": cache.count]
    }
}
