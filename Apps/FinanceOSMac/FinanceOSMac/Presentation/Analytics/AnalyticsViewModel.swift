import FinanceCore
import FinanceIntelligence
import FinanceUI
import Foundation

@Observable @MainActor
class AnalyticsViewModel: AsyncLoadable {
    var monthlySummaries: [MonthlySpendingSummary] = []
    var merchantSummaries: [MerchantSummary] = []
    var categorySpend: [CategorySpendSummary] = []
    var insights: [TransactionInsight] = []
    var recentFluctuations: [FluctuationRow] = []
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

    // MARK: - Display Strings

    var totalOutflowText: String {
        MoneyFormatting.formatRounded(minorUnits: totalOutflow)
    }

    var categoryTotalText: String {
        let total = categorySpend.reduce(Int64(0)) { $0 + $1.totalDebit }
        return MoneyFormatting.formatRounded(minorUnits: total)
    }

    var periodLabel: String {
        guard let first = monthlySummaries.first?.id, let last = monthlySummaries.last?.id else { return "" }
        let year = Calendar.current.component(.year, from: last)
        let firstLabel = FormatterCache.shortMonth.string(from: first).uppercased()
        let lastLabel = FormatterCache.shortMonth.string(from: last).uppercased()
        return "\(firstLabel)-\(lastLabel) \(year)"
    }

    // MARK: - Load

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
                let fluctTxns = aggregator.fluctuationTransactions(from: insights, all: allTransactions)
                recentFluctuations = fluctTxns.map { txn in
                    FluctuationRow(
                        id: txn.id,
                        merchantName: txn.merchantName ?? txn.description,
                        dateText: FormatterCache.dayMonthCommaYear.string(from: txn.postedAt),
                        currencyCode: txn.currencyCode,
                        amountText: MoneyFormatting.formatWithSign(
                            minorUnits: txn.amountMinorUnits,
                            isDebit: txn.transactionType == .debit
                        ),
                        isDebit: txn.transactionType == .debit,
                        sourceTransaction: txn
                    )
                }
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
