import Foundation

/// Fixture example for seeding dataset.
struct FixtureExample {
    let narration: String
    let label: String
    let bank: String
}

/// Orchestrates full ML-001 dataset collection from multiple sources.
///
/// Workflow:
/// 1. Collect from parser fixtures
/// 2. Collect from FeedbackStore (user corrections)
/// 3. Generate synthetic examples for gaps
/// 4. Validate, deduplicate, export
public actor DatasetOrchestrator {
    private var collector: DatasetCollector

    public init() {
        self.collector = DatasetCollector(
            annotationGuidelines: Self.annotationGuidelinesText
        )
    }

    /// Seed from parser fixtures.
    public func seedFromFixtures() async {
        for example in Self.seedFixtureExamples {
            guard let labelEnum = LabeledNarration.NarrationLabel(rawValue: example.label) else {
                continue
            }
            await collector.addFromFixture(
                narration: example.narration,
                label: labelEnum,
                bank: example.bank,
                direction: .debit
            )
        }
    }

    /// Collect from FeedbackStore user corrections.
    public func collectFromFeedbackStore(_ store: FeedbackStore) async throws {
        let dataCollector = FeedbackStoreDataCollector(feedbackStore: store)
        let examples = try await dataCollector.collectAll()

        for ex in examples {
            guard let labelEnum = LabeledNarration.NarrationLabel(rawValue: ex.label) else {
                continue
            }
            await collector.addFromUserCorrection(
                narration: ex.narration,
                merchantName: nil,
                label: labelEnum,
                bank: "unknown",
                direction: .debit
            )
        }
    }

    /// Add synthetic examples for underrepresented patterns.
    public func generateSynthetic() async {
        let syntheticExamples = Self.generateSyntheticNarrations()
        for (narration, label) in syntheticExamples {
            guard let labelEnum = LabeledNarration.NarrationLabel(rawValue: label) else {
                continue
            }
            await collector.addSynthetic(
                narration: narration,
                label: labelEnum,
                bank: "synthetic",
                direction: .debit
            )
        }
    }

    /// Get final dataset.
    public func buildDataset() async -> LabeledNarrationCollection {
        await collector.buildDataset()
    }

    /// Export dataset.
    public func exportJSON() async throws -> Data {
        try await collector.exportJSON()
    }

    public func exportCSV() async -> String {
        await collector.exportCSV()
    }

    // MARK: - Private

    private static let seedFixtureExamples: [FixtureExample] = [
        FixtureExample(narration: "UPI-JOHN DOE-9876543210@upi-HDFC0-REF1", label: "person", bank: "HDFC"),
        FixtureExample(narration: "UPI-RAJESH SHARMA-9123456789@ybl-ICIC0-REF2", label: "person", bank: "ICICI"),
        FixtureExample(narration: "NEFT CR-HDFC0-PRIYA PATEL-REF3", label: "person", bank: "HDFC"),
        FixtureExample(narration: "IMPS-1234-AMIT KUMAR-REF4", label: "person", bank: "AXIS"),
        FixtureExample(narration: "UPI-NEHA GUPTA-9988776655@upi-IDBI0-REF5", label: "person", bank: "IDBI"),
        FixtureExample(narration: "UPI-SWIGGY-swiggy@swiggypay-HDFC0-REF6", label: "merchant", bank: "HDFC"),
        FixtureExample(narration: "UPI-AMAZON-amazonpay@razorpay-ICIC0-REF7", label: "merchant", bank: "ICICI"),
        FixtureExample(narration: "NEFT DR-ICIC0-NETFLIX INDIA PVT LTD-REF8", label: "merchant", bank: "ICICI"),
        FixtureExample(narration: "UPI-ZOMATO INDIA-zomato@sbi-REF9", label: "merchant", bank: "SBI"),
        FixtureExample(narration: "NEFT CR-HDFC0-UBER INDIA PRIVATE LIMITED-REF10", label: "merchant", bank: "HDFC"),
        FixtureExample(narration: "UPI-FLIPKART-flipkart@okaxis-REF11", label: "merchant", bank: "AXIS")
    ]

    private static func generateSyntheticNarrations() -> [(String, String)] {
        var examples: [(String, String)] = []

        // Synthetic person patterns
        let personNames = [
            "Ashok Kumar", "Deepa Singh", "Vikram Patel", "Sneha Gupta",
            "Rohan Sharma", "Ananya Roy"
        ]
        let personVPAs = [
            "9876543210@upi", "9123456789@ybl", "9988776655@upi",
            "9445123456@okicici"
        ]

        for name in personNames {
            for vpa in personVPAs.prefix(2) {
                let phone = vpa.components(separatedBy: "@").first ?? ""
                examples.append((
                    "UPI-\(name)-\(vpa)-HDFC0-REF",
                    "person"
                ))
            }
        }

        // Synthetic merchant patterns (brand names with variants)
        let merchants = [
            ("MYNTRA", "merchant"),
            ("AJIO", "merchant"),
            ("NYKAA", "merchant"),
            ("MEESHO", "merchant"),
            ("UNACADEMY", "merchant"),
            ("BYJU'S", "merchant"),
            ("CURE.FIT", "merchant"),
            ("DUNZO", "merchant")
        ]

        for (name, label) in merchants {
            examples.append(("UPI-\(name)-\(name.lowercased())@swiggypay-REF", label))
            examples.append(("NEFT CR-HDFC0-\(name) INDIA PVT LTD-REF", label))
        }

        // Synthetic unknown patterns (truncated, garbled)
        let unknown = [
            "UPI-ABC123-REF456",
            "TRANSFER REFERENCE XYZ",
            "INT PAID ON DEPOSIT",
            "NEFT-UNKNOWN-12345",
            "UPI/AAABBBCCC/"
        ]

        for narration in unknown {
            examples.append((narration, "unknown"))
        }

        return examples
    }

    private static let annotationGuidelinesText = """
    Person vs Merchant Classification Guidelines

    PERSON: P2P transfer between individuals
    - VPA with phone number (9XXXXXXXXX@bank, 91XXXXXXXXXXX@bank)
    - Person name without business suffix
    - NEFT/IMPS with person's first + last name

    MERCHANT: Business transaction
    - Business suffixes (Ltd, Pvt, Private Limited, Services, Solutions)
    - Known merchant brands (Amazon, Swiggy, Netflix, etc.)
    - Payment gateway VPAs (razorpay, cashfree, etc.)

    UNKNOWN: Cannot classify confidently
    - Truncated or garbled narration
    - Ambiguous names
    - Missing context
    """
}
