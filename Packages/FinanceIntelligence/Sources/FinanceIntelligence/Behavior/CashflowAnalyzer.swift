import FinanceCore
import Foundation

/// Computes monthly income/expense snapshots from a transaction corpus.
/// Groups transactions by calendar month, sums credits (income) and debits (expense),
/// then averages across all months.
public struct CashflowAnalyzer: Sendable {
    public init() {}

    public struct TransactionRecord: Sendable {
        public let amount: Int64
        public let isDebit: Bool
        public let postedAt: Date
        /// Category taxonomy ID (e.g. "income.salary", "transfers", "investments.sip").
        /// Used to exclude non-real income/expense from cashflow calculations.
        public let categoryId: String?
        /// Intent raw value (e.g. "credit_card_payment", "transfer", "mutual_fund_sip").
        public let intentId: String?

        public init(amount: Int64, isDebit: Bool, postedAt: Date, categoryId: String? = nil, intentId: String? = nil) {
            self.amount = amount
            self.isDebit = isDebit
            self.postedAt = postedAt
            self.categoryId = categoryId
            self.intentId = intentId
        }
    }

    public struct MonthlySnapshot: Sendable {
        public let monthKey: String
        public let totalIncome: Int64
        public let totalExpense: Int64
        public var net: Int64 {
            totalIncome - totalExpense
        }
    }

    /// Compute a monthly summary for each calendar month in the dataset.
    public func monthlySnapshots(from transactions: [TransactionRecord]) -> [MonthlySnapshot] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: transactions) { txn -> String in
            let comps = cal.dateComponents([.year, .month], from: txn.postedAt)
            return String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
        }
        return grouped.map { key, records in
            let income = records
                .filter {
                    TransactionFilter.isRealIncome(
                        isCredit: !$0.isDebit,
                        categoryId: $0.categoryId,
                        intentId: $0.intentId
                    )
                }
                .map(\.amount).reduce(0, +)
            let expense = records
                .filter {
                    TransactionFilter.isRealExpense(
                        isDebit: $0.isDebit,
                        categoryId: $0.categoryId,
                        intentId: $0.intentId
                    )
                }
                .map(\.amount).reduce(0, +)
            return MonthlySnapshot(monthKey: key, totalIncome: income, totalExpense: expense)
        }.sorted { $0.monthKey < $1.monthKey }
    }

    /// Aggregate monthly snapshots into a single CashFlowSummary.
    public func summarize(snapshots: [MonthlySnapshot]) -> CashFlowSummary {
        guard !snapshots.isEmpty else {
            return CashFlowSummary(averageMonthlyIncome: 0, averageMonthlyExpense: 0)
        }
        let avgIncome = snapshots.map(\.totalIncome).reduce(0, +) / Int64(snapshots.count)
        let avgExpense = snapshots.map(\.totalExpense).reduce(0, +) / Int64(snapshots.count)
        return CashFlowSummary(averageMonthlyIncome: avgIncome, averageMonthlyExpense: avgExpense)
    }

    /// Convenience: compute summary directly from raw transactions.
    public func analyze(transactions: [TransactionRecord]) -> CashFlowSummary {
        summarize(snapshots: monthlySnapshots(from: transactions))
    }
}
