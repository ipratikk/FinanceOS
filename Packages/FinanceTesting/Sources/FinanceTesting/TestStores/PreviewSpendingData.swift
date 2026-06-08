import FinanceCore
import Foundation

/// Preview/test data for spending summaries.
public enum PreviewSpendingData {
    public static var currentTotals: SpendingTotals {
        SpendingTotals(
            totalDebit: 234_567,
            totalCredit: 500_000,
            transactionCount: 47
        )
    }

    public static var monthlySummaries: [MonthlySpendingSummary] {
        let calendar = Calendar(identifier: .gregorian)
        let now = SnapshotConfiguration.referenceDate
        return (0 ..< 6).reversed().map { offset in
            let month = calendar.date(byAdding: .month, value: -offset, to: now) ?? now
            return MonthlySpendingSummary(
                month: month,
                totalDebit: Int64(180_000 + offset * 20000),
                totalCredit: Int64(500_000)
            )
        }
    }

    public static var netWorthSeries: [NetWorthPoint] {
        let calendar = Calendar(identifier: .gregorian)
        let now = SnapshotConfiguration.referenceDate
        return (0 ..< 6).reversed().map { offset in
            let date = calendar.date(byAdding: .month, value: -offset, to: now) ?? now
            let netWorthMinorUnits = Int64((100_000 + offset * 10000) * 100)
            return NetWorthPoint(timestamp: date, netWorthMinorUnits: netWorthMinorUnits)
        }
    }
}
