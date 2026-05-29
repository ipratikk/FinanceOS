import FinanceCore
import FinanceIntelligence
import Foundation

struct CategorySpendSummary: Identifiable {
    let id: String
    let displayName: String
    let totalDebit: Int64
    let percentage: Double
    let transactionCount: Int
}

struct MerchantSummary: Identifiable {
    var id: String {
        name
    }

    let name: String
    let totalDebit: Int64
    let transactionCount: Int
    let maxTotal: Int64

    var initials: String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var proportion: Double {
        maxTotal > 0 ? Double(totalDebit) / Double(maxTotal) : 0
    }
}

@Observable @MainActor
class AnalyticsViewModel: AsyncLoadable {
    var monthlySummaries: [MonthlySpendingSummary] = []
    var merchantSummaries: [MerchantSummary] = []
    var categorySpend: [CategorySpendSummary] = []
    var insights: [TransactionInsight] = []
    var recentFluctuations: [Transaction] = []
    var totalOutflow: Int64 = 0
    var outflowChange: Double?
    var isLoading = false
    var error: String?

    private let spendingService: any SpendingServiceProtocol
    private let transactionRepository: any TransactionReader
    private let intelligenceService: (any TransactionIntelligenceService)?
    private let aggregator: any AnalyticsAggregatorProtocol

    init(
        spendingService: any SpendingServiceProtocol,
        transactionRepository: any TransactionReader,
        intelligenceService: (any TransactionIntelligenceService)? = nil,
        aggregator: any AnalyticsAggregatorProtocol
    ) {
        self.spendingService = spendingService
        self.transactionRepository = transactionRepository
        self.intelligenceService = intelligenceService
        self.aggregator = aggregator
    }

    func load() async {
        await withLoading(onError: { [self] error in
            self.error = error.localizedDescription
            FinanceLogger.userInterface.logError("Analytics load failed", caughtError: error, [:])
        }, {
            monthlySummaries = try await spendingService.monthlySummary(months: 6)
            let allTransactions = try await transactionRepository.fetchTransactions()
            totalOutflow = monthlySummaries.reduce(0) { $0 + $1.totalDebit }
            outflowChange = computeOutflowChange()
            merchantSummaries = aggregator.aggregateMerchants(allTransactions)
            categorySpend = aggregator.aggregateCategorySpend(allTransactions)
            if let service = intelligenceService {
                insights = await (try? service.generateInsights(for: allTransactions)) ?? []
                recentFluctuations = aggregator.fluctuationTransactions(from: insights, all: allTransactions)
            }
        })
    }

    private func computeOutflowChange() -> Double? {
        guard monthlySummaries.count >= 2 else { return nil }
        let recent = monthlySummaries.suffix(3).reduce(0) { $0 + $1.totalDebit }
        let prior = monthlySummaries.prefix(3).reduce(0) { $0 + $1.totalDebit }
        guard prior > 0 else { return nil }
        return Double(recent - prior) / Double(prior) * 100
    }
}
