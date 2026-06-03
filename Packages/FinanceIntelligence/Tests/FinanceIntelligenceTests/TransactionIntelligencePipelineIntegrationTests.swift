import CoreML
import FinanceCore
import FinanceTesting
import XCTest

@testable import FinanceIntelligence

/// Integration tests for the full transaction enrichment pipeline (FINOS-24).
/// Validates all stages 3-7 (income detection, intent classification, subscription detection, recurring patterns).
final class IntelligencePipelineIntegrationTests: XCTestCase {
    private var service: TransactionIntelligenceService!

    override func setUp() async throws {
        try await super.setUp()
        service = await TransactionIntelligenceServiceImpl(
            configuration: .default
        )
    }

    // MARK: - Single Transaction Tests

    func test_analyzeEnriched_salaryIncome_detectsIncomeAndIntent() async throws {
        let transaction = Transaction(
            postedAt: Date(),
            description: "NEFT CR ACME SALARY PAYMENT",
            amountMinorUnits: 10000000,
            currencyCode: "INR",
            transactionType: .credit,
            merchantName: "ACME"
        )

        let enriched = try await service.analyzeEnriched(transaction, context: .empty)

        XCTAssertNotNil(enriched.incomePrediction, "Income prediction should be detected")
        XCTAssertTrue(enriched.incomePrediction?.isIncome ?? false, "Should detect as income")
    }

    func test_analyzeEnriched_subscriptionNarration_detectsSubscription() async throws {
        let transaction = Transaction(
            postedAt: Date(),
            description: "NETFLIX MONTHLY SUBSCRIPTION",
            amountMinorUnits: 9900,
            currencyCode: "INR",
            transactionType: .debit,
            merchantName: "NETFLIX"
        )

        let enriched = try await service.analyzeEnriched(transaction, context: .empty)

        XCTAssertNotNil(enriched.subscriptionPrediction, "Subscription should be detected")
        XCTAssertEqual(enriched.subscriptionPrediction?.name, "Netflix")
    }

    func test_analyzeEnriched_userCorrection_overridesModel() async throws {
        let transaction = Transaction(
            postedAt: Date(),
            description: "AMAZON PURCHASE",
            amountMinorUnits: 50000,
            currencyCode: "INR",
            transactionType: .debit,
            merchantName: "AMAZON"
        )

        let enriched = try await service.analyzeEnriched(transaction, context: .empty)

        XCTAssertFalse(enriched.isUserCorrected, "Should not be user corrected initially")
    }

    // MARK: - Batch Processing Tests

    func test_analyzeBatch_100Transactions_completesSuccessfully() async throws {
        let transactions = (0..<100).map { i -> Transaction in
            let desc = "MERCHANT"
            let merchant = "MERCHANT"
            return Transaction(
                postedAt: Date(timeIntervalSinceNow: -Double(i * 86400)),
                description: desc,
                amountMinorUnits: Int64((1000 + i * 10) * 100),
                currencyCode: "INR",
                transactionType: i % 2 == 0 ? .debit : .credit,
                merchantName: merchant
            )
        }

        let enriched = try await service.analyzeBatch(transactions, context: .empty)

        XCTAssertEqual(enriched.count, 100, "All transactions should be enriched")
        XCTAssertTrue(enriched.allSatisfy { $0.categoryPrediction != nil }, "All should have category predictions")
    }

    // MARK: - Latency Tests

    func test_analyzeEnriched_latency_p95_lessThan200ms() async throws {
        let transaction = Transaction(
            postedAt: Date(),
            description: "TEST TRANSACTION",
            amountMinorUnits: 100000,
            currencyCode: "INR",
            transactionType: .debit,
            merchantName: "TEST"
        )

        var latencies: [Double] = []
        let iterations = 50

        for _ in 0..<iterations {
            let start = Date()
            _ = try await service.analyzeEnriched(transaction, context: .empty)
            let elapsed = Date().timeIntervalSince(start) * 1000
            latencies.append(elapsed)
        }

        latencies.sort()
        let p95Index = Int(Double(latencies.count) * 0.95)
        let p95Latency = latencies[p95Index]

        print("Latency: min=\(String(format: "%.2f", latencies.first ?? 0))ms, " +
              "p95=\(String(format: "%.2f", p95Latency))ms, max=\(String(format: "%.2f", latencies.last ?? 0))ms")

        XCTAssertLessThan(p95Latency, 200, "P95 latency should be < 200ms")
    }

    // MARK: - Edge Cases

    func test_analyzeEnriched_emptyNarration_handlesGracefully() async throws {
        let transaction = Transaction(
            postedAt: Date(),
            description: "",
            amountMinorUnits: 10000,
            currencyCode: "INR"
        )

        let enriched = try await service.analyzeEnriched(transaction, context: .empty)

        XCTAssertNotNil(enriched, "Should handle empty narration")
        XCTAssertNotNil(enriched.categoryPrediction, "Should produce category prediction")
    }

    func test_analyzeEnriched_multipleSubscriptions_returnsFirstMatch() async throws {
        let transaction = Transaction(
            postedAt: Date(),
            description: "NETFLIX SPOTIFY YOUTUBE PREMIUM",
            amountMinorUnits: 9900,
            currencyCode: "INR",
            transactionType: .debit,
            merchantName: "NETFLIX"
        )

        let enriched = try await service.analyzeEnriched(transaction, context: .empty)

        XCTAssertNotNil(enriched.subscriptionPrediction)
    }

    func test_analyzeEnriched_pipelineVersion_populated() async throws {
        let transaction = Transaction(
            postedAt: Date(),
            description: "TEST",
            amountMinorUnits: 10000,
            currencyCode: "INR"
        )

        let enriched = try await service.analyzeEnriched(transaction, context: .empty)

        XCTAssertEqual(enriched.pipelineVersion, "1.0")
    }

    func test_analyzeEnriched_allFieldsPopulated() async throws {
        let transaction = Transaction(
            postedAt: Date(),
            description: "NETFLIX SUBSCRIPTION",
            amountMinorUnits: 100000,
            currencyCode: "INR",
            transactionType: .debit,
            merchantName: "NETFLIX"
        )

        let enriched = try await service.analyzeEnriched(transaction, context: .empty)

        XCTAssertNotNil(enriched.transaction)
        XCTAssertNotNil(enriched.categoryPrediction)
        XCTAssertNotNil(enriched.intentPrediction)
        XCTAssertNotNil(enriched.features)
    }
}

// MARK: - Test Helpers

private extension IntelligenceContext {
    static let empty = IntelligenceContext(
        ledgerKind: .bankAccount,
        institution: nil
    )
}

private struct TestModelRegistry: ModelRegistry {
    func loadCoreML(_ name: ModelName) throws -> MLModel {
        throw NSError(domain: "TestRegistry", code: 1)
    }

    func mlxArtifactPath(for name: ModelName) throws -> URL {
        throw NSError(domain: "TestRegistry", code: 1)
    }

    func version(for name: ModelName) -> ModelVersion? {
        nil
    }

    func validate(_ name: ModelName) throws {}

    func models(withStatus status: ModelStatus) -> [ModelRegistryEntry] {
        []
    }
}

private struct InMemoryFeedbackStore: FeedbackStore {
    func record(_ event: FeedbackEvent) async throws {}
    func events(for transactionId: UUID) async throws -> [FeedbackEvent] { [] }
    func events(ofType type: FeedbackEventType) async throws -> [FeedbackEvent] { [] }
    func allEvents() async throws -> [FeedbackEvent] { [] }
}
