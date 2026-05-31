import FinanceCore
import Foundation

/// Detects salary credit cycles from a transaction corpus.
/// Identifies months with large income-category credits, infers the typical
/// day-of-month and amount, and scores confidence by consistency.
public struct SalaryAnalyzer: Sendable {
    /// Minimum amount (in minor units) to qualify as a salary candidate.
    private let minimumSalaryMinorUnits: Int64

    public init(minimumSalaryMinorUnits: Int64 = 2_000_000) {
        self.minimumSalaryMinorUnits = minimumSalaryMinorUnits
    }

    public struct SalaryCandidate: Sendable {
        public let transactionId: UUID
        public let amount: Int64
        public let postedAt: Date
        public let categoryId: String
        public let intentId: String
    }

    /// Detect salary cycle from eligible credit transactions.
    /// Candidates: credits with categoryId "income" or intentId "salary".
    public func analyzeCycle(from candidates: [SalaryCandidate]) -> SalaryCycle? {
        let eligible = candidates.filter {
            $0.amount >= minimumSalaryMinorUnits &&
            ($0.categoryId == "income" || $0.intentId == "salary" ||
             $0.intentId == "income")
        }
        guard eligible.count >= 2 else { return nil }

        let byMonth = groupByMonth(eligible)
        guard byMonth.count >= 2 else { return nil }

        let monthlySalaries = byMonth.values.compactMap { monthGroup -> SalaryCandidate? in
            monthGroup.max { $0.amount < $1.amount }
        }

        let cal = Calendar.current
        let days = monthlySalaries.map { cal.component(.day, from: $0.postedAt) }.sorted()
        let avgDay = days[days.count / 2]

        let amounts = monthlySalaries.map(\.amount)
        let avgAmount = amounts.reduce(0, +) / Int64(amounts.count)

        let sampleBonus = min(Double(monthlySalaries.count) / 6.0, 1.0) * 0.2
        let confidence = min(0.70 + sampleBonus, 0.92)

        return SalaryCycle(
            averageDayOfMonth: avgDay,
            averageAmountMinorUnits: avgAmount,
            confidence: confidence,
            sources: monthlySalaries.map(\.transactionId)
        )
    }

    // MARK: - Private

    private func groupByMonth(_ candidates: [SalaryCandidate]) -> [String: [SalaryCandidate]] {
        let cal = Calendar.current
        return Dictionary(grouping: candidates) { candidate in
            let comps = cal.dateComponents([.year, .month], from: candidate.postedAt)
            return String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
        }
    }
}
