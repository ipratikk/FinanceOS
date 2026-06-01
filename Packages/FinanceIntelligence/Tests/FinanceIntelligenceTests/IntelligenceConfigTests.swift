@testable import FinanceIntelligence
import Foundation
import Testing

@Suite("IntelligenceConfig — defaultV1 matches hardcoded baselines")
struct IntelligenceConfigTests {
    private let cfg = IntelligenceConfig.defaultV1

    @Test("Classification thresholds match previous inline values")
    func classificationThresholdsMatchBaseline() {
        #expect(cfg.classification.ruleConfidenceThreshold == 0.92)
        #expect(cfg.classification.knnConfidenceThreshold == 0.70)
        #expect(cfg.classification.nlModelConfidenceThreshold == nil)
    }

    @Test("Relationship thresholds match previous inline values")
    func relationshipThresholdsMatchBaseline() {
        #expect(cfg.relationship.minConfidence == 0.40)
        #expect(cfg.relationship.postSalaryWindowDays == 7)
        #expect(cfg.relationship.roundAmountGranularityMinorUnits == 50000)
        #expect(cfg.relationship.minTransactionsForInference == 2)
    }

    @Test("Recurring config matches previous inline values")
    func recurringConfigMatchesBaseline() {
        #expect(cfg.recurring.minOccurrencesDefault == 2)
        #expect(cfg.recurring.amountCVThreshold == 0.15)
    }

    @Test("Insight thresholds match previous inline values")
    func insightThresholdsMatchBaseline() {
        #expect(cfg.insight.spikeStdDevMultiplier == 2.0)
        #expect(cfg.insight.anomalyStdDevMultiplier == 3.0)
        #expect(!cfg.insight.exposeConfidenceToUser)
    }

    @Test("Graph config matches previous inline values")
    func graphConfigMatchesBaseline() {
        #expect(cfg.graph.edgeWeightIncrement == 0.1)
        #expect(cfg.graph.edgeWeightMax == 10.0)
    }

    @Test("defaultV1 is Codable — round-trips through JSON")
    func defaultV1RoundTripsJSON() throws {
        let data = try JSONEncoder().encode(IntelligenceConfig.defaultV1)
        let decoded = try JSONDecoder().decode(IntelligenceConfig.self, from: data)
        #expect(decoded == IntelligenceConfig.defaultV1)
    }

    @Test("IntelligenceConfigLoader returns defaultV1 for missing file")
    func loaderReturnsFallbackForMissingFile() {
        let loader = IntelligenceConfigLoader()
        let url = URL(fileURLWithPath: "/nonexistent/path/config.json")
        let loaded = loader.load(from: url)
        #expect(loaded == IntelligenceConfig.defaultV1)
    }
}
