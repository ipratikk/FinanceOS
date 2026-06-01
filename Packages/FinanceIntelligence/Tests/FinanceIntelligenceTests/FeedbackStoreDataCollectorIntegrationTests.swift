@testable import FinanceIntelligence
import Foundation
import Testing

/// Integration tests showing how FeedbackStore data flows into dataset collection.
///
/// These tests demonstrate the complete workflow for collecting real labeled data
/// from user corrections (merchant_corrected, category_corrected events).

@Test
func feedbackStoreDataCollector_merchantCorrectionMapping() async {
    // Simulate user correction event
    let event = FeedbackEvent(
        eventType: .merchantCorrected,
        entityType: "transaction",
        entityId: "txn-123",
        transactionId: UUID(),
        oldValue: "UPI/Unknown",
        newValue: "Swiggy Food Pvt Ltd",
        source: "user_correction",
        modelVersion: "v1",
        configVersion: "c1"
    )

    // Mock store returns the event
    struct MockStore: FeedbackStore {
        func record(_ event: FeedbackEvent) async throws {}

        func events(for transactionId: UUID) async throws -> [FeedbackEvent] {
            []
        }

        func events(ofType type: FeedbackEventType) async throws -> [FeedbackEvent] {
            [event]
        }

        func allEvents() async throws -> [FeedbackEvent] {
            [event]
        }
    }

    let mockStore = MockStore()
    let collector = FeedbackStoreDataCollector(feedbackStore: mockStore)

    // Collect from merchant corrections
    let examples = try await collector.collectFromMerchantCorrections()

    #expect(!examples.isEmpty)
    #expect(examples[0].narration == "Swiggy Food Pvt Ltd")
    #expect(examples[0].label == "merchant")
    #expect(examples[0].confidence >= 0.8)
}

@Test
func feedbackStoreDataCollector_categoryToLabelMapping() async {
    // Simulate category correction (e.g., salary deposit)
    let salaryEvent = FeedbackEvent(
        eventType: .categoryCorrected,
        entityType: "transaction",
        entityId: "txn-456",
        transactionId: UUID(),
        oldValue: "shopping",
        newValue: "salary",
        source: "user_correction",
        modelVersion: "v1",
        configVersion: "c1",
        metadataJson: "{\"merchantName\": \"Employer Inc\"}"
    )

    struct MockStore: FeedbackStore {
        func record(_ event: FeedbackEvent) async throws {}
        func events(for transactionId: UUID) async throws -> [FeedbackEvent] { [] }
        func events(ofType type: FeedbackEventType) async throws -> [FeedbackEvent] {
            [salaryEvent]
        }
        func allEvents() async throws -> [FeedbackEvent] { [] }
    }

    let mockStore = MockStore()
    let collector = FeedbackStoreDataCollector(feedbackStore: mockStore)

    let examples = try await collector.collectFromCategoryCorrections()

    #expect(!examples.isEmpty)
    #expect(examples[0].label == "person") // salary → person transfer
    #expect(examples[0].confidence >= 0.6)
}

@Test
func datasetOrchestrator_integrateFeedbackStore() async throws {
    let orchestrator = DatasetOrchestrator()

    // Seed with fixtures
    await orchestrator.seedFromFixtures()

    // Mock FeedbackStore with sample events
    struct MockStore: FeedbackStore {
        func record(_ event: FeedbackEvent) async throws {}
        func events(for transactionId: UUID) async throws -> [FeedbackEvent] { [] }

        func events(ofType type: FeedbackEventType) async throws -> [FeedbackEvent] {
            if type == .merchantCorrected {
                return [
                    FeedbackEvent(
                        eventType: .merchantCorrected,
                        entityType: "transaction",
                        entityId: "txn-1",
                        transactionId: UUID(),
                        oldValue: nil,
                        newValue: "Netflix India",
                        source: "user_correction"
                    )
                ]
            }
            return []
        }

        func allEvents() async throws -> [FeedbackEvent] { [] }
    }

    // Collect from feedback
    try await orchestrator.collectFromFeedbackStore(MockStore())

    // Add synthetic
    await orchestrator.generateSynthetic()

    // Build final dataset
    let dataset = await orchestrator.buildDataset()

    // Verify collection
    #expect(dataset.examples.count > 12) // seed + feedback + synthetic
    #expect(!dataset.metadata.sourceCoverage.isEmpty)
}

@Test
func datasetValidator_acceptsIntegratedDataset() async {
    let orchestrator = DatasetOrchestrator()

    // Build dataset from all sources
    await orchestrator.seedFromFixtures()
    await orchestrator.generateSynthetic()
    let dataset = await orchestrator.buildDataset()

    // Validate
    let validator = DatasetValidator()
    let report = validator.validate(dataset)

    // Should have valid data (though may warn about small size)
    #expect(report.issues.isEmpty) // no critical issues
    #expect(!report.metrics.summary.isEmpty)
    #expect(report.metrics.totalCount > 10)
}

@Test
func classifierEvaluator_onIntegratedDataset() async throws {
    let orchestrator = DatasetOrchestrator()

    // Build dataset
    await orchestrator.seedFromFixtures()
    await orchestrator.generateSynthetic()
    let dataset = await orchestrator.buildDataset()

    // Evaluate baseline classifier
    let classifier = PersonMerchantClassifier()
    let evaluator = ClassifierEvaluator()
    let metrics = evaluator.evaluate(classifier: classifier, against: dataset)

    // Verify metrics generation
    #expect(metrics.accuracy >= 0.0 && metrics.accuracy <= 1.0)
    #expect(!metrics.summary.isEmpty)
    #expect(metrics.summary.contains("person"))
}
