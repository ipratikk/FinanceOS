import FinanceCore
import FinanceIntelligence
import FinanceOSAPI
import FinanceUI
import Foundation

@Observable @MainActor
final class InsightNarrativeViewModel {
    struct InsightItem: Identifiable {
        var id: String {
            text
        }

        let text: String
        let severity: NarrativeSeverity
    }

    var insights: [InsightItem] = []
    var isLoading = false
    var lastRefreshDate: Date?

    private let graphQLClient: ApolloGraphQLClient
    private let generator = MLXInsightGenerator()
    private static let lastRefreshKey = "InsightNarrative.lastRefresh"

    init(graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
        lastRefreshDate = UserDefaults.standard.object(forKey: Self.lastRefreshKey) as? Date
    }

    func refreshIfNeeded() async {
        guard let last = lastRefreshDate else {
            await refresh()
            return
        }
        let thirtyDays: TimeInterval = 30 * 24 * 60 * 60
        if Date().timeIntervalSince(last) > thirtyDays {
            await refresh()
        }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let txnsData = try await graphQLClient.fetch(
                query: GetTransactionsQuery(ledgerId: .none, filter: .none, limit: .none)
            )
            let allTransactions = txnsData.transactions.map(GraphQLMappings.mapTransaction)
            let currentMonthTxns = currentMonthTransactions(allTransactions)
            guard let context = buildContext(from: currentMonthTxns, allTransactions: allTransactions) else {
                insights = []
                return
            }
            let gen = generator
            let raw = await Task.detached(priority: .userInitiated) {
                gen.generate(from: context)
            }.value
            insights = raw.map { InsightItem(text: $0.text, severity: mapSeverity($0.severity)) }
            lastRefreshDate = Date()
            UserDefaults.standard.set(lastRefreshDate, forKey: Self.lastRefreshKey)
        } catch {
            insights = []
        }
    }

    private func currentMonthTransactions(_ transactions: [Transaction]) -> [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        return transactions.filter { $0.postedAt >= startOfMonth }
    }

    private func buildContext(
        from currentMonth: [Transaction],
        allTransactions: [Transaction]
    ) -> InsightGenerationContext? {
        guard currentMonth.count >= 5 else { return nil }

        let totalSpend = currentMonth
            .filter { $0.transactionType == .debit }
            .reduce(0) { $0 + Int($1.amountMinorUnits) }

        let prevMonthTxns = previousMonthTransactions(allTransactions)
        let prevSpend = prevMonthTxns
            .filter { $0.transactionType == .debit }
            .reduce(0) { $0 + Int($1.amountMinorUnits) }

        let categoryBreakdown = buildCategoryBreakdown(current: currentMonth, previous: prevMonthTxns)
        let topMerchants = buildTopMerchants(currentMonth)
        let totalCredit = currentMonth
            .filter { $0.transactionType == .credit }
            .reduce(0) { $0 + Int($1.amountMinorUnits) }
        let netCashflow = totalCredit - totalSpend

        return InsightGenerationContext(
            month: Date(),
            totalSpendMinorUnits: totalSpend,
            previousMonthSpendMinorUnits: prevSpend,
            categoryBreakdown: categoryBreakdown,
            topMerchants: topMerchants,
            recurringCount: 0,
            recurringTotalMinorUnits: 0,
            anomalyCount: 0,
            netCashflowMinorUnits: netCashflow
        )
    }

    private func previousMonthTransactions(_ transactions: [Transaction]) -> [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfCurrentMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ),
            let startOfPrevMonth = calendar.date(byAdding: .month, value: -1, to: startOfCurrentMonth)
        else { return [] }
        return transactions.filter { $0.postedAt >= startOfPrevMonth && $0.postedAt < startOfCurrentMonth }
    }

    private func buildCategoryBreakdown(
        current: [Transaction],
        previous: [Transaction]
    ) -> [InsightGenerationContext.CategorySpend] {
        var currentByCategory: [String: Int] = [:]
        for txn in current where txn.transactionType == .debit {
            let key = txn.categoryId ?? "uncategorized"
            currentByCategory[key, default: 0] += Int(txn.amountMinorUnits)
        }
        var prevByCategory: [String: Int] = [:]
        for txn in previous where txn.transactionType == .debit {
            let key = txn.categoryId ?? "uncategorized"
            prevByCategory[key, default: 0] += Int(txn.amountMinorUnits)
        }
        return currentByCategory.map { categoryId, total in
            let prev = prevByCategory[categoryId] ?? 0
            let changePct: Double = prev > 0
                ? Double(total - prev) / Double(prev) * 100
                : 0
            return InsightGenerationContext.CategorySpend(
                categoryId: categoryId,
                displayName: categoryId.replacingOccurrences(of: "_", with: " ").capitalized,
                totalMinorUnits: total,
                previousMonthMinorUnits: prev,
                changePercent: changePct
            )
        }
    }

    private func buildTopMerchants(_ transactions: [Transaction]) -> [(merchant: String, totalMinorUnits: Int)] {
        var byMerchant: [String: Int] = [:]
        for txn in transactions where txn.transactionType == .debit {
            let key = txn.merchantName ?? txn.description
            byMerchant[key, default: 0] += Int(txn.amountMinorUnits)
        }
        return byMerchant
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { (merchant: $0.key, totalMinorUnits: $0.value) }
    }

    private func mapSeverity(_ severity: InsightSeverity) -> NarrativeSeverity {
        switch severity {
        case .info: .info
        case .warning: .warning
        case .alert: .alert
        }
    }
}
