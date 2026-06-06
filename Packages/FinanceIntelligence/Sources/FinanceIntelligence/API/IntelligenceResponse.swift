import FinanceCore
import Foundation

/// Typed response enum for all intelligence service operations.
public enum IntelligenceResponse: Sendable {
    case categorize(CategorizeResponse)
    case analyzeSpending(SpendingAnalysisResponse)
    case detectRecurring(RecurringDetectionResponse)
    case detectSalary(SalaryDetectionResponse)
    case analyzeCashflow(CashflowResponse)
    case resolveEntities(EntityResolutionResponse)
    case generateInsight(InsightResponse)
    case enrichTransaction(EnrichTransactionResponse)
}

public struct EnrichTransactionResponse: Sendable {
    public let enriched: Int
    public let skipped: Int
    public let reconciled: Int
    public let descriptions: [UUID: String]

    public init(enriched: Int, skipped: Int, reconciled: Int, descriptions: [UUID: String]) {
        self.enriched = enriched
        self.skipped = skipped
        self.reconciled = reconciled
        self.descriptions = descriptions
    }
}

public struct CategorizeResponse: Sendable {
    public let processed: Int
    public let succeeded: Int
    public let failed: Int
    public let results: [UUID: CategoryPrediction]

    public init(processed: Int, succeeded: Int, failed: Int, results: [UUID: CategoryPrediction]) {
        self.processed = processed
        self.succeeded = succeeded
        self.failed = failed
        self.results = results
    }
}

public struct SpendingAnalysisResponse: Sendable {
    public let totalSpend: Decimal
    public let byCategory: [String: Decimal]
    public let topMerchants: [MerchantSpendSummary]
    public let insights: [TransactionInsight]

    public init(
        totalSpend: Decimal,
        byCategory: [String: Decimal],
        topMerchants: [MerchantSpendSummary],
        insights: [TransactionInsight]
    ) {
        self.totalSpend = totalSpend
        self.byCategory = byCategory
        self.topMerchants = topMerchants
        self.insights = insights
    }
}

public struct MerchantSpendSummary: Sendable {
    public let name: String
    public let totalSpend: Decimal
    public let transactionCount: Int

    public init(name: String, totalSpend: Decimal, transactionCount: Int) {
        self.name = name
        self.totalSpend = totalSpend
        self.transactionCount = transactionCount
    }
}

public struct RecurringDetectionResponse: Sendable {
    public let patterns: [RecurringPattern]

    public init(patterns: [RecurringPattern]) {
        self.patterns = patterns
    }
}

public struct SalaryDetectionResponse: Sendable {
    public let detected: Bool
    public let estimatedMonthlySalary: Decimal?
    public let confidence: Double

    public init(detected: Bool, estimatedMonthlySalary: Decimal?, confidence: Double) {
        self.detected = detected
        self.estimatedMonthlySalary = estimatedMonthlySalary
        self.confidence = confidence
    }
}

public struct CashflowResponse: Sendable {
    public let netCashflow: Decimal
    public let totalInflow: Decimal
    public let totalOutflow: Decimal

    public init(netCashflow: Decimal, totalInflow: Decimal, totalOutflow: Decimal) {
        self.netCashflow = netCashflow
        self.totalInflow = totalInflow
        self.totalOutflow = totalOutflow
    }
}

public struct EntityResolutionResponse: Sendable {
    public let resolvedPersonCount: Int
    public let resolvedMerchantCount: Int

    public init(resolvedPersonCount: Int, resolvedMerchantCount: Int) {
        self.resolvedPersonCount = resolvedPersonCount
        self.resolvedMerchantCount = resolvedMerchantCount
    }
}

public struct InsightResponse: Sendable {
    public let narrative: String
    public let dataPoints: [String: String]

    public init(narrative: String, dataPoints: [String: String]) {
        self.narrative = narrative
        self.dataPoints = dataPoints
    }
}
