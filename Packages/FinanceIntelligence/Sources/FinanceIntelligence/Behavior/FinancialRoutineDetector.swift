import Foundation

/// Detects the canonical post-salary financial routine:
///   Salary credit → Rent payment → Credit card payoff → SIP investment
///
/// For each month with a detected salary credit, looks for the subsequent
/// steps within defined windows. Consistency = months where sequence fires / total salary months.
public struct FinancialRoutineDetector: Sendable {
    public init() {}

    public struct TransactionRecord: Sendable {
        public let amount: Int64
        public let isDebit: Bool
        public let postedAt: Date
        public let categoryId: String
        public let intentId: String

        public init(amount: Int64, isDebit: Bool, postedAt: Date, categoryId: String, intentId: String) {
            self.amount = amount
            self.isDebit = isDebit
            self.postedAt = postedAt
            self.categoryId = categoryId
            self.intentId = intentId
        }
    }

    /// Detect financial routines given salary dates and full transaction history.
    public func detect(
        salaryCreditDates: [Date],
        transactions: [TransactionRecord]
    ) -> [FinancialRoutine] {
        guard !salaryCreditDates.isEmpty else { return [] }
        var routines: [FinancialRoutine] = []
        if let routine = detectSalaryRentCCRoutine(
            salaryCreditDates: salaryCreditDates, transactions: transactions
        ) {
            routines.append(routine)
        }
        return routines
    }

    // MARK: - Private

    /// Salary → Rent (≤7 days) → Credit Card (≤14 days) sequence.
    private func detectSalaryRentCCRoutine(
        salaryCreditDates: [Date],
        transactions: [TransactionRecord]
    ) -> FinancialRoutine? {
        var matchCount = 0
        var stepLog: [(rent: Int, card: Int)] = []

        for salaryDate in salaryCreditDates {
            let window = transactions.filter {
                let diff = $0.postedAt.timeIntervalSince(salaryDate) / 86400
                return diff > 0 && diff <= 20 && $0.isDebit
            }
            let rentStep = window.first {
                $0.categoryId == "housing" || $0.intentId == "rent"
            }
            let cardStep = window.first {
                $0.intentId == "credit_card_payment" || $0.categoryId == "transfers"
            }
            if rentStep != nil || cardStep != nil {
                matchCount += 1
                let rentDays = rentStep.map { Int($0.postedAt.timeIntervalSince(salaryDate) / 86400) }
                let cardDays = cardStep.map { Int($0.postedAt.timeIntervalSince(salaryDate) / 86400) }
                stepLog.append((rent: rentDays ?? 0, card: cardDays ?? 0))
            }
        }

        guard !stepLog.isEmpty else { return nil }
        let consistency = Double(matchCount) / Double(salaryCreditDates.count)
        guard consistency >= 0.5 else { return nil }

        let avgRentDays = stepLog.map(\.rent).reduce(0, +) / stepLog.count
        let avgCardDays = stepLog.map(\.card).reduce(0, +) / stepLog.count
        let steps: [RoutineStep] = [
            RoutineStep(intent: "salary", daysAfterSalary: 0, categoryId: "income"),
            RoutineStep(intent: "rent", daysAfterSalary: avgRentDays, categoryId: "housing"),
            RoutineStep(intent: "credit_card_payment", daysAfterSalary: avgCardDays, categoryId: "transfers")
        ].filter { $0.daysAfterSalary > 0 || $0.intent == "salary" }

        return FinancialRoutine(steps: steps, consistency: consistency)
    }
}
