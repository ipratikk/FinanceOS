import FinanceCore
import FinanceOSAPI
import FinanceUI
import Foundation

enum TimeRange: String, CaseIterable, Identifiable {
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "All"

    var id: String {
        rawValue
    }

    var months: Int? {
        switch self {
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .oneYear: return 12
        case .all: return nil
        }
    }

    var visibleDays: Int? {
        switch self {
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        case .all: return nil
        }
    }
}

@Observable @MainActor
class DashboardViewModel: AsyncLoadable {
    var currentTotals: SpendingTotals?
    var monthlySummaries: [MonthlySpendingSummary] = []
    // Net worth series not available from GraphQL backend — chart hidden when empty
    var netWorthTimeSeries: [NetWorthPoint] = []
    var recentTransactions: [TransactionRow] = []
    var isLoading = false
    var error: String?
    var selectedTimeRange: TimeRange = .sixMonths
    var ledgers: [Ledger] = []

    var effectiveTotals: SpendingTotals? {
        if let totals = currentTotals, totals.transactionCount > 0 { return totals }
        guard let last = monthlySummaries.last else { return currentTotals }
        return SpendingTotals(totalDebit: last.totalDebit, totalCredit: last.totalCredit, transactionCount: 0)
    }

    var effectiveMonth: Date {
        if let totals = currentTotals, totals.transactionCount > 0 { return Date() }
        return monthlySummaries.last?.month ?? Date()
    }

    var currentNetWorth: Decimal {
        guard let point = netWorthTimeSeries.last else { return 0 }
        return Decimal(point.netWorthMinorUnits) / 100
    }

    var netWorthMoMDelta: Double? {
        guard let latest = netWorthTimeSeries.last else { return nil }
        let calendar = Calendar.current
        guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: latest.timestamp) else { return nil }
        guard let prevPoint = netWorthTimeSeries.min(by: {
            abs($0.timestamp.timeIntervalSince(oneMonthAgo)) < abs($1.timestamp.timeIntervalSince(oneMonthAgo))
        }), prevPoint.netWorthMinorUnits != 0 else { return nil }
        let latestNW = Decimal(latest.netWorthMinorUnits) / 100
        let prevNW = Decimal(prevPoint.netWorthMinorUnits) / 100
        let delta = (latestNW - prevNW) / abs(prevNW)
        return (delta as NSDecimalNumber).doubleValue
    }

    // MARK: - Display Strings

    var currentNetWorthText: String {
        FormatterCache.formatCurrency(currentNetWorth, currencyCode: "INR")
    }

    var netWorthMoMDeltaText: String? {
        guard let delta = netWorthMoMDelta else { return nil }
        return delta >= 0 ? String(format: "+%.1f%%", delta * 100) : String(format: "%.1f%%", delta * 100)
    }

    var netWorthDeltaIsPositive: Bool {
        (netWorthMoMDelta ?? 0) >= 0
    }

    var inflowsText: String {
        FormatterCache.formatCurrency(minorUnits: effectiveTotals?.totalCredit ?? 0)
    }

    var outflowsText: String {
        FormatterCache.formatCurrency(minorUnits: effectiveTotals?.totalDebit ?? 0)
    }

    var netSavingsText: String {
        let net = max(0, (effectiveTotals?.totalCredit ?? 0) - (effectiveTotals?.totalDebit ?? 0))
        return FormatterCache.formatCurrency(minorUnits: net)
    }

    var transactionCountBadge: String {
        guard let count = effectiveTotals?.transactionCount, count > 0 else { return "" }
        return "\(count) Txns"
    }

    func openingBalanceText(for ledger: Ledger) -> String? {
        guard let balance = ledger.openingBalance else { return nil }
        return FormatterCache.formatCurrency(minorUnits: balance)
    }

    func editingBalanceString(for ledger: Ledger) -> String {
        guard let balance = ledger.openingBalance, balance != 0 else { return "" }
        return "\(Decimal(balance) / 100)"
    }

    // MARK: - Dependencies

    private let graphQLClient: ApolloGraphQLClient
    private let exportService: any ExportServiceProtocol

    init(
        graphQLClient: ApolloGraphQLClient,
        exportService: any ExportServiceProtocol
    ) {
        self.graphQLClient = graphQLClient
        self.exportService = exportService
    }

    func load() async {
        await withLoading(onError: { [self] error in
            self.error = error.localizedDescription
            FinanceLogger.userInterface.logError("Dashboard load failed", caughtError: error, [:])
        }, {
            let fromStr: GraphQLNullable<String> = selectedTimeRange.months.flatMap {
                Calendar.current.date(byAdding: .month, value: -$0, to: Date())
            }.map { .some(ISO8601DateFormatter().string(from: $0)) } ?? .none

            async let analyticsResult = graphQLClient.fetch(query: GetAnalyticsQuery(
                ledgerId: .none,
                from: fromStr,
                to: .none
            ))
            async let recentResult = graphQLClient.fetch(query: GetTransactionsQuery(
                ledgerId: .none,
                filter: .none,
                limit: .some(6)
            ))
            async let ledgersResult = graphQLClient.fetch(query: GetLedgersQuery())

            let (analyticsData, recentData, ledgersData) = try await (analyticsResult, recentResult, ledgersResult)
            let analytics = analyticsData.analytics

            monthlySummaries = analytics.byMonth.map(GraphQLMappings.mapMonthly)
            currentTotals = SpendingTotals(
                totalDebit: Int64(analytics.totalSpend * 100),
                totalCredit: Int64(analytics.totalIncome * 100),
                transactionCount: 0
            )
            recentTransactions = makeRecentRows(recentData.transactions.map(GraphQLMappings.mapTransaction))
            ledgers = ledgersData.ledgers.map(GraphQLMappings.mapLedger)
        })
    }

    func setTimeRange(_ range: TimeRange) async {
        selectedTimeRange = range
        await load()
    }

    func exportNetWorthCSV() -> String {
        exportService.netWorthCSV(series: [])
    }

    // MARK: - Private Mapping

    private func makeRecentRows(_ transactions: [Transaction]) -> [TransactionRow] {
        transactions.map { txn in
            TransactionRow(
                id: txn.id,
                title: txn.description,
                subtitle: "",
                amountText: txn.amountMinorUnits.formattedAsAmount(
                    currencyCode: txn.currencyCode,
                    transactionType: txn.transactionType
                ),
                amountMinorUnits: abs(txn.amountMinorUnits),
                transactionType: txn.transactionType,
                postedAt: txn.postedAt,
                merchantName: txn.merchantName,
                categoryId: txn.categoryId,
                sourceTransaction: txn,
                enrichedDescription: txn.enrichedDescription
            )
        }
    }
}
