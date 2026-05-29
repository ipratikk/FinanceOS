import SwiftUI

/// Thread-safe image cache to eliminate AsyncImage memory churn.
/// Caches loaded images to prevent repeated downloads/loads.
public actor ImageCache {
    public static let shared = ImageCache()

    private var cache: [URL: Image] = [:]

    // MARK: - Public API

    /// Returns a cached `Image` for the given URL, or `nil` if not yet cached.
    public func image(for url: URL?) -> Image? {
        guard let url else { return nil }
        return cache[url]
    }

    /// Stores `image` in the cache keyed by `url`.
    public func setImage(_ image: Image, for url: URL) {
        cache[url] = image
    }

    /// Evicts the image for the given URL from the cache.
    public func removeImage(for url: URL) {
        cache.removeValue(forKey: url)
    }

    /// Evicts all images from the cache.
    public func clearCache() {
        cache.removeAll()
    }

    // MARK: - Cache Statistics

    /// Number of images currently held in memory.
    public var cacheSize: Int {
        cache.count
    }

    public func cacheStats() -> [String: Any] {
        ["cacheSize": cache.count]
    }
}
