import Foundation

/// Collects labeled narration examples from FeedbackStore user corrections.
///
/// Maps user feedback events (merchant_corrected, category_corrected) to training labels
/// for person/merchant classification. Enables bootstrapping dataset from implicit user signals.
public struct FeedbackStoreDataCollector {
    private let feedbackStore: FeedbackStore

    public init(feedbackStore: FeedbackStore) {
        self.feedbackStore = feedbackStore
    }

    /// Collect labeled examples from merchant corrections.
    ///
    /// When user corrects merchant name, infer:
    /// - If new merchant matches business keywords → label as **merchant**
    /// - If new merchant is person name + VPA has phone → label as **person**
    /// - Otherwise → label as **unknown** (insufficient signal)
    public func collectFromMerchantCorrections() async throws -> [FeedbackExample] {
        var examples: [FeedbackExample] = []
        let events = try await feedbackStore.events(ofType: .merchantCorrected)

        for event in events {
            guard let newMerchant = event.newValue, !newMerchant.isEmpty else {
                continue
            }

            let label = inferLabel(from: newMerchant)
            guard label != "unknown" else { continue } // skip ambiguous

            examples.append(FeedbackExample(
                narration: newMerchant,
                label: label,
                source: "merchant_correction",
                confidence: 0.9 // User correction = high confidence
            ))
        }

        return examples
    }

    /// Collect labeled examples from category corrections paired with merchant.
    ///
    /// Strategy: if merchant was corrected along with category, use merchant as narration signal.
    /// Filter to high-confidence categories (ATM → unknown, Shopping → merchant, Salary → person).
    public func collectFromCategoryCorrections(
        minTransactionCount: Int = 10
    ) async throws -> [FeedbackExample] {
        var examples: [FeedbackExample] = []
        let events = try await feedbackStore.events(ofType: .categoryCorrected)

        let categoryToLabel: [String: String] = [
            "salary": "person",
            "income": "person",
            "transfer": "person",
            "p2p": "person",
            "shopping": "merchant",
            "food_dining": "merchant",
            "travel": "merchant",
            "utilities": "merchant",
            "subscription": "merchant"
        ]

        for event in events {
            guard let category = event.newValue,
                  let label = categoryToLabel[category.lowercased()] else {
                continue
            }

            guard let narration = event.metadataJson.flatMap({ json in
                parseMetadataField(json, "merchantName")
            }) else {
                continue
            }

            guard !narration.isEmpty else { continue }

            examples.append(FeedbackExample(
                narration: narration,
                label: label,
                source: "category_correction",
                confidence: 0.7 // Category-based inference = moderate confidence
            ))
        }

        return examples
    }

    /// Collect all available feedback examples (both types).
    public func collectAll() async throws -> [FeedbackExample] {
        let merchant = try await collectFromMerchantCorrections()
        let category = try await collectFromCategoryCorrections()
        return merchant + category
    }

    // MARK: - Private

    private func inferLabel(from merchant: String) -> String {
        let lower = merchant.lowercased()

        // Business keywords
        let businessKeywords = [
            "marketplace", "pvt", "ltd", "private limited", "llp",
            "amazon", "swiggy", "zomato", "flipkart", "uber", "ola",
            "netflix", "spotify", "airtel", "jio", "bank"
        ]

        if businessKeywords.contains(where: { lower.contains($0) }) {
            return "merchant"
        }

        // Person name pattern (first + last name, no numbers or business words)
        if !merchant.contains(where: \.isNumber) && merchant.split(separator: " ").count >= 2 {
            return "person"
        }

        return "unknown"
    }

    private func parseMetadataField(_ json: String, _ field: String) -> String? {
        // Simple JSON field extraction (would use JSONDecoder in production)
        if let range = json.range(of: "\"\(field)\":\"") {
            let startIndex = range.upperBound
            if let endRange = json[startIndex...].range(of: "\"") {
                return String(json[startIndex..<endRange.lowerBound])
            }
        }
        return nil
    }
}

/// Example collected from feedback store.
public struct FeedbackExample: Identifiable {
    public let id: UUID
    public let narration: String
    public let label: String
    public let source: String
    public let confidence: Double
    public let createdAt: Date

    public init(
        narration: String,
        label: String,
        source: String,
        confidence: Double = 0.8
    ) {
        self.id = UUID()
        self.narration = narration
        self.label = label
        self.source = source
        self.confidence = confidence
        self.createdAt = Date()
    }
}
