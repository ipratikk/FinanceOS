import Foundation

/// Classifies narrations as person, merchant, or unknown for P2P vs B2C detection.
///
/// Baseline: keyword + pattern matching (heuristic).
/// Goal (ML-002): Train neural model that beats keyword baseline on held-out test set.
///
/// Training approach:
/// 1. Baseline: keyword heuristics (current)
/// 2. ML phase 1: Rule ensemble + feature engineering
/// 3. ML phase 2: Neural classifier (once 5,000+ examples available)
public struct PersonMerchantClassifier: Sendable {
    public enum Label: String, Codable, Sendable {
        case person
        case merchant
        case unknown
    }

    public enum Confidence: Double, Comparable, Sendable {
        case certain = 0.95
        case high = 0.80
        case moderate = 0.60
        case low = 0.40

        public static func < (lhs: Confidence, rhs: Confidence) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public struct Prediction: Sendable {
        public let label: Label
        public let confidence: Confidence
        public let evidence: [String]
    }

    private let features: NarrationFeatureExtractor

    public init() {
        features = NarrationFeatureExtractor()
    }

    /// Classify narration (baseline keyword heuristic).
    public func classify(_ narration: String) -> Prediction {
        let feat = features.extract(narration)

        // Phone number VPA → person (highest confidence)
        if feat.hasPhoneVPA {
            return Prediction(
                label: .person,
                confidence: .certain,
                evidence: ["phone_vpa"]
            )
        }

        // Merchant gateway VPA → merchant
        if feat.hasMerchantGatewayVPA {
            return Prediction(
                label: .merchant,
                confidence: .certain,
                evidence: ["merchant_gateway_vpa"]
            )
        }

        // Business keywords → merchant
        if feat.hasBusinessKeywords {
            let keywords = feat.businessKeywordsMatched
            return Prediction(
                label: .merchant,
                confidence: feat.businessKeywordCount >= 2 ? .high : .moderate,
                evidence: keywords.map { "keyword:\($0)" }
            )
        }

        // Person name pattern (2+ words, no numbers) → person
        if feat.looksLikeName, !feat.hasNumbers {
            return Prediction(
                label: .person,
                confidence: .moderate,
                evidence: ["name_pattern"]
            )
        }

        // Default to unknown
        return Prediction(
            label: .unknown,
            confidence: .low,
            evidence: ["no_signal"]
        )
    }

    /// Batch classify narrations.
    public func classify(_ narrations: [String]) -> [Prediction] {
        narrations.map { classify($0) }
    }

    /// Score confidence for evaluation (0.0 to 1.0).
    public func confidenceScore(_ prediction: Prediction) -> Double {
        prediction.confidence.rawValue
    }
}

/// Feature extraction for narration classification.
struct NarrationFeatureExtractor {
    struct Features {
        let hasPhoneVPA: Bool
        let hasMerchantGatewayVPA: Bool
        let hasBusinessKeywords: Bool
        let businessKeywordsMatched: [String]
        let businessKeywordCount: Int
        let looksLikeName: Bool
        let hasNumbers: Bool
    }

    private let gatewayTokens: [String]

    private static let businessKeywords = [
        "marketplace", "pvt", "ltd", "private limited", "llp",
        "amazon", "flipkart", "swiggy", "zomato", "uber", "ola",
        "netflix", "spotify", "airtel", "jio", "bank", "insurance",
        "retail", "services", "enterprises", "solutions", "trading"
    ]

    init() {
        gatewayTokens = MerchantGatewayConfig.load().tokens
    }

    func extract(_ narration: String) -> Features {
        let lower = narration.lowercased()

        // Check VPA patterns
        let hasPhoneVPA = checkPhoneVPA(narration)
        let hasMerchantGateway = gatewayTokens.contains { lower.contains($0) }

        // Check business keywords
        let matched = Self.businessKeywords.filter { lower.contains($0) }
        let hasKeywords = !matched.isEmpty

        // Check name pattern (2+ words)
        let words = narration.split(separator: " ").filter { !$0.isEmpty }
        let looksLikeName = words.count >= 2

        // Check for numbers
        let hasNumbers = narration.contains { $0.isNumber }

        return Features(
            hasPhoneVPA: hasPhoneVPA,
            hasMerchantGatewayVPA: hasMerchantGateway,
            hasBusinessKeywords: hasKeywords,
            businessKeywordsMatched: matched,
            businessKeywordCount: matched.count,
            looksLikeName: looksLikeName,
            hasNumbers: hasNumbers
        )
    }

    private func checkPhoneVPA(_ narration: String) -> Bool {
        guard narration.contains("@") else { return false }

        // Extract VPA prefix (before @)
        let parts = narration.components(separatedBy: "@")
        guard let vpaPrefix = parts.first else { return false }

        // Get last segment (after last - or /)
        let segments = vpaPrefix.components(separatedBy: CharacterSet(charactersIn: "-/"))
        guard let lastSegment = segments.last else { return false }

        let cleaned = lastSegment.filter(\.isNumber)
        // 10 digits = Indian phone, 12 digits = with country code
        return cleaned.count == 10 || cleaned.count == 12
    }
}
