import FinanceCore
import Foundation

protocol AnalyticsAggregatorProtocol: Sendable {
    func aggregateMerchants(_ transactions: [Transaction]) -> [MerchantSummary]
    func aggregateCategorySpend(_ transactions: [Transaction]) -> [CategorySpendSummary]
}

struct AnalyticsAggregatorService: AnalyticsAggregatorProtocol {
    func aggregateMerchants(_ transactions: [Transaction]) -> [MerchantSummary] {
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

    func aggregateCategorySpend(_ transactions: [Transaction]) -> [CategorySpendSummary] {
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
}
