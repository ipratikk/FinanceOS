import FinanceCore
import FinanceIntelligence
import FinanceOSAPI
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

    private let graphQLClient: ApolloGraphQLClient
    private let intelligenceService: (any TransactionIntelligenceService)?
    private let aggregator: any AnalyticsAggregatorProtocol

    init(
        graphQLClient: ApolloGraphQLClient,
        intelligenceService: (any TransactionIntelligenceService)? = nil,
        aggregator: any AnalyticsAggregatorProtocol
    ) {
        self.graphQLClient = graphQLClient
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
            let from = Calendar.current.date(byAdding: .month, value: -6, to: Date())
            let fromStr: GraphQLNullable<String> = from.map { .some(ISO8601DateFormatter().string(from: $0)) } ?? .none

            async let analyticsResult = graphQLClient.fetch(query: GetAnalyticsQuery(
                ledgerId: .none, from: fromStr, to: .none
            ))
            async let txnsResult = graphQLClient.fetch(query: GetTransactionsQuery(
                ledgerId: .none, filter: .none, limit: .none
            ))
            let (analyticsData, txnsData) = try await (analyticsResult, txnsResult)

            monthlySummaries = analyticsData.analytics.byMonth.map(GraphQLMappings.mapMonthly)
            totalOutflow = monthlySummaries.reduce(0) { $0 + $1.totalDebit }
            outflowChange = computeOutflowChange()

            let allTransactions = txnsData.transactions.map(GraphQLMappings.mapTransaction)
            merchantSummaries = aggregator.aggregateMerchants(allTransactions)
            categorySpend = aggregator.aggregateCategorySpend(allTransactions)

            if let service = intelligenceService {
                insights = await (try? service.generateInsights(for: allTransactions)) ?? []
                let fluctTxns = aggregator.fluctuationTransactions(from: insights, all: allTransactions)
                recentFluctuations = mapFluctuations(fluctTxns)
            }
        })
    }

    // MARK: - Private Helpers

    private func mapFluctuations(_ transactions: [Transaction]) -> [FluctuationRow] {
        transactions.map { txn in
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

    private func computeOutflowChange() -> Double? {
        guard monthlySummaries.count >= 2 else { return nil }
        let recent = monthlySummaries.suffix(3).reduce(0) { $0 + $1.totalDebit }
        let prior = monthlySummaries.prefix(3).reduce(0) { $0 + $1.totalDebit }
        guard prior > 0 else { return nil }
        return Double(recent - prior) / Double(prior) * 100
    }
}
