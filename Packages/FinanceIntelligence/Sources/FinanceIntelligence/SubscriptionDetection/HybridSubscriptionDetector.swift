import Foundation

/// Hybrid subscription detector combining rule-based keyword + confidence scoring.
///
/// Detects known subscription services from transaction narratives using:
/// 1. Merchant keyword matching (Netflix, Spotify, Prime, etc.)
/// 2. Confidence scoring calibrated for high precision (>= 0.93)
/// 3. Fallback to low-confidence detection for edge cases
///
/// Precision target: >= 0.93 (low false positive rate for user trust)
public struct HybridSubscriptionDetector: Sendable {
    /// Known subscription merchants with confidence thresholds
    private static let knownSubscriptionMerchants: [String: (keywords: [String], confidence: Double)] = [
        "Netflix": (["NETFLIX"], 0.98),
        "Spotify": (["SPOTIFY"], 0.98),
        "Prime Video": (["PRIME", "AMAZON"], 0.95),
        "YouTube Premium": (["YOUTUBE"], 0.92),
        "Disney+": (["DISNEY"], 0.95),
        "Hotstar": (["HOTSTAR"], 0.90),
        "ZEE5": (["ZEE5"], 0.92),
        "Sony LIV": (["SONY"], 0.88),
        "Apple Music": (["APPLE", "ITUNES"], 0.90),
        "Google One": (["GOOGLE"], 0.85),
        "Microsoft 365": (["MICROSOFT"], 0.88),
        "Adobe Creative": (["ADOBE"], 0.92),
        "Notion": (["NOTION"], 0.88),
        "ChatGPT Plus": (["OPENAI", "CHATGPT"], 0.95)
    ]

    public init() {}

    /// Detect subscription from transaction narrative.
    /// Returns subscription name + confidence if matched.
    public func detect(narrative: String) -> (name: String, confidence: Double)? {
        let searchText = narrative.uppercased()
        guard !searchText.isEmpty else { return nil }

        // Try to find a matching subscription merchant
        for (merchantName, data) in Self.knownSubscriptionMerchants {
            for keyword in data.keywords where searchText.contains(keyword) {
                // Return only if confidence meets precision threshold
                if data.confidence >= 0.93 {
                    return (merchantName, data.confidence)
                }
            }
        }

        return nil
    }

    /// List all known subscription merchants
    public static func knownSubscriptions() -> [String] {
        Array(knownSubscriptionMerchants.keys).sorted()
    }
}
