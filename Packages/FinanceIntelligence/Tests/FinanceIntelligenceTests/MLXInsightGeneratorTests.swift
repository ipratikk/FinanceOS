@testable import FinanceIntelligence
import Foundation
import Testing

@Suite("MLXInsightGenerator — grounded narratives, hallucination guard")
struct MLXInsightGeneratorTests {
    let gen = MLXInsightGenerator()
    let month = ISO8601DateFormatter().date(from: "2026-05-01T00:00:00Z") ?? Date()

    private func makeContext(
        total: Int = 500_000, prevTotal: Int = 400_000,
        anomalies: Int = 0, recurring: Int = 3
    ) -> InsightGenerationContext {
        InsightGenerationContext(
            month: month,
            totalSpendMinorUnits: total,
            previousMonthSpendMinorUnits: prevTotal,
            categoryBreakdown: [
                .init(
                    categoryId: "food",
                    displayName: "Food",
                    totalMinorUnits: 200_000,
                    previousMonthMinorUnits: 150_000,
                    changePercent: 33.3
                ),
                .init(
                    categoryId: "travel",
                    displayName: "Travel",
                    totalMinorUnits: 100_000,
                    previousMonthMinorUnits: 100_000,
                    changePercent: 0
                )
            ],
            topMerchants: [("Swiggy", 120_000), ("Uber", 80000)],
            recurringCount: recurring,
            recurringTotalMinorUnits: 150_000,
            anomalyCount: anomalies,
            netCashflowMinorUnits: 2_000_000
        )
    }

    @Test("Generates 3-5 insights for populated context")
    func insightCount() {
        let insights = gen.generate(from: makeContext())
        #expect(insights.count >= 3)
        #expect(insights.count <= 5)
    }

    @Test("All insights are grounded (no hallucination)")
    func allInsightsGrounded() {
        let insights = gen.generate(from: makeContext())
        // Hoisted out of #expect: the macro mis-analyses a key-path arg as throwing.
        let allGrounded = insights.allSatisfy(\.isGrounded)
        #expect(allGrounded)
    }

    @Test("Insights are non-empty strings")
    func nonEmptyInsights() {
        let insights = gen.generate(from: makeContext())
        #expect(insights.allSatisfy { !$0.text.isEmpty })
    }

    @Test("Spend insight contains actual amount")
    func spendInsightContainsAmount() {
        let insights = gen.generate(from: makeContext(total: 500_000))
        let spendInsight = insights.first { $0.kind == .spendingSpike }
        #expect(spendInsight?.text.contains("5000") == true)
    }

    @Test("Spend spike marked as warning when >20% increase")
    func spendSpikeWarning() {
        let insights = gen.generate(from: makeContext(total: 600_000, prevTotal: 400_000))
        let spendInsight = insights.first { $0.kind == .spendingSpike }
        #expect(spendInsight?.severity == .warning)
    }

    @Test("Anomaly insight generated when anomalies present")
    func anomalyInsightPresent() {
        let insights = gen.generate(from: makeContext(anomalies: 2))
        let anomaly = insights.first { $0.severity == .alert }
        #expect(anomaly != nil)
        #expect(anomaly?.text.contains("2") == true)
    }

    @Test("No anomaly insight when zero anomalies")
    func noAnomalyInsightWhenNone() {
        let insights = gen.generate(from: makeContext(anomalies: 0))
        let anomaly = insights.first { $0.kind == .unusuallyLargeTransaction }
        #expect(anomaly == nil)
    }

    @Test("Recurring insight contains count and amount")
    func recurringInsight() {
        let insights = gen.generate(from: makeContext(recurring: 3))
        let recurring = insights.first { $0.kind == .recurringTransaction }
        #expect(recurring?.text.contains("3") == true)
        #expect(recurring?.text.contains("1500") == true)
    }

    @Test("Top merchant insight names the merchant")
    func topMerchantInsight() {
        let insights = gen.generate(from: makeContext())
        let merchant = insights.first { $0.kind == .merchantTrend }
        #expect(merchant?.text.contains("Swiggy") == true)
    }

    @Test("Empty context returns zero or minimal insights")
    func emptyContextInsights() {
        let ctx = InsightGenerationContext(
            month: month, totalSpendMinorUnits: 0, previousMonthSpendMinorUnits: 0,
            categoryBreakdown: [], topMerchants: [],
            recurringCount: 0, recurringTotalMinorUnits: 0,
            anomalyCount: 0, netCashflowMinorUnits: 0
        )
        let insights = gen.generate(from: ctx)
        #expect(insights.isEmpty || insights.allSatisfy { !$0.text.isEmpty })
    }
}
