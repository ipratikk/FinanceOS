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

    init(
        spendingService: any SpendingServiceProtocol,
        transactionRepository: any TransactionReader,
        intelligenceService: (any TransactionIntelligenceService)? = nil
    ) {
        self.spendingService = spendingService
        self.transactionRepository = transactionRepository
        self.intelligenceService = intelligenceService
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
            merchantSummaries = aggregateMerchants(from: allTransactions)
            categorySpend = aggregateCategorySpend(from: allTransactions)
            if let service = intelligenceService {
                insights = await (try? service.generateInsights(for: allTransactions)) ?? []
                recentFluctuations = fluctuationTransactions(from: insights, all: allTransactions)
            }
        })
    }
}

// MARK: - Aggregation

private extension AnalyticsViewModel {
    func computeOutflowChange() -> Double? {
        guard monthlySummaries.count >= 2 else { return nil }
        let recent = monthlySummaries.suffix(3).reduce(0) { $0 + $1.totalDebit }
        let prior = monthlySummaries.prefix(3).reduce(0) { $0 + $1.totalDebit }
        guard prior > 0 else { return nil }
        return Double(recent - prior) / Double(prior) * 100
    }

    func aggregateMerchants(from transactions: [Transaction]) -> [MerchantSummary] {
        var totals: [String: (Int64, Int)] = [:]
        for txn in transactions where txn.transactionType == .debit {
            let key = txn.merchantName ?? txn.description
            let current = totals[key] ?? (0, 0)
            totals[key] = (current.0 + txn.amountMinorUnits, current.1 + 1)
        }
        let sorted = totals.sorted { $0.value.0 > $1.value.0 }.prefix(8)
        let max = sorted.first?.value.0 ?? 1
        return sorted.map { name, data in
            MerchantSummary(name: name, totalDebit: data.0, transactionCount: data.1, maxTotal: max)
        }
    }

    func aggregateCategorySpend(from transactions: [Transaction]) -> [CategorySpendSummary] {
        let taxonomy = CategoryTaxonomy.current
        var totals: [String: (Int64, Int)] = [:]
        for txn in transactions where txn.transactionType == .debit {
            let key = txn.categoryId ?? "uncategorized"
            let current = totals[key] ?? (0, 0)
            totals[key] = (current.0 + txn.amountMinorUnits, current.1 + 1)
        }
        let grandTotal = totals.values.reduce(0) { $0 + $1.0 }
        guard grandTotal > 0 else { return [] }
        return totals
            .map { categoryId, data in
                let name = taxonomy.category(forId: categoryId)?.displayName ?? categoryId.capitalized
                let pct = Double(data.0) / Double(grandTotal) * 100
                return CategorySpendSummary(
                    id: categoryId, displayName: name,
                    totalDebit: data.0, percentage: pct, transactionCount: data.1
                )
            }
            .sorted { $0.totalDebit > $1.totalDebit }
    }

    func fluctuationTransactions(from insights: [TransactionInsight], all: [Transaction]) -> [Transaction] {
        let flucIds = Set(
            insights
                .filter { $0.kind == .unusuallyLargeTransaction }
                .flatMap(\.affectedTransactionIDs)
        )
        return all.filter { flucIds.contains($0.id.uuidString) }.prefix(5).map(\.self)
    }
}
