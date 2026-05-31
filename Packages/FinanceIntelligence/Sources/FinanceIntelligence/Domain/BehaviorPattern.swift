import Foundation

/// Computed summary of the user's financial behavior patterns.
/// Derived from recurring patterns, salary credits, and transaction history.
/// Not stored in DB — recomputed when needed from persisted underlying data.
public struct BehaviorPattern: Sendable, Codable {
    /// Detected salary credit cycle.
    public let salaryCycle: SalaryCycle?
    /// Detected rent payment pattern (monthly debit to a person).
    public let rentCycle: RecurringPattern?
    /// Detected credit card payoff pattern (CRED/AmEx monthly debit).
    public let creditCardPayoffCycle: RecurringPattern?
    /// Detected SIP/mutual fund investment pattern.
    public let sipCycle: RecurringPattern?
    /// Average monthly income/expense snapshot.
    public let monthlyCashFlow: CashFlowSummary
    /// Detected post-salary financial sequence (salary→rent→CC→SIP).
    public let financialRoutines: [FinancialRoutine]

    public init(
        salaryCycle: SalaryCycle? = nil,
        rentCycle: RecurringPattern? = nil,
        creditCardPayoffCycle: RecurringPattern? = nil,
        sipCycle: RecurringPattern? = nil,
        monthlyCashFlow: CashFlowSummary,
        financialRoutines: [FinancialRoutine] = []
    ) {
        self.salaryCycle = salaryCycle
        self.rentCycle = rentCycle
        self.creditCardPayoffCycle = creditCardPayoffCycle
        self.sipCycle = sipCycle
        self.monthlyCashFlow = monthlyCashFlow
        self.financialRoutines = financialRoutines
    }
}

/// Detected salary credit cycle inferred from recurring income transactions.
public struct SalaryCycle: Sendable, Codable {
    /// Median day of month when salary arrives.
    public let averageDayOfMonth: Int
    public let averageAmountMinorUnits: Int64
    /// Confidence in [0, 1]. Scales with months of evidence.
    public let confidence: Double
    /// Transaction IDs contributing to this cycle.
    public let sources: [UUID]

    public init(averageDayOfMonth: Int, averageAmountMinorUnits: Int64, confidence: Double, sources: [UUID]) {
        self.averageDayOfMonth = averageDayOfMonth
        self.averageAmountMinorUnits = averageAmountMinorUnits
        self.confidence = confidence
        self.sources = sources
    }
}

/// Average monthly income and expense snapshot.
public struct CashFlowSummary: Sendable, Codable {
    public let averageMonthlyIncome: Int64
    public let averageMonthlyExpense: Int64
    /// (income − expense) / income. Negative = spending > earning.
    public let savingsRate: Double

    public init(averageMonthlyIncome: Int64, averageMonthlyExpense: Int64) {
        self.averageMonthlyIncome = averageMonthlyIncome
        self.averageMonthlyExpense = averageMonthlyExpense
        savingsRate = averageMonthlyIncome > 0
            ? Double(averageMonthlyIncome - averageMonthlyExpense) / Double(averageMonthlyIncome)
            : 0
    }
}

/// A detected post-salary financial routine (e.g. salary→rent→credit-card→SIP).
public struct FinancialRoutine: Sendable, Codable {
    public let steps: [RoutineStep]
    /// Fraction of months where this exact sequence was observed.
    public let consistency: Double

    public init(steps: [RoutineStep], consistency: Double) {
        self.steps = steps
        self.consistency = consistency
    }
}

public struct RoutineStep: Sendable, Codable {
    public let intent: String
    public let daysAfterSalary: Int
    public let categoryId: String

    public init(intent: String, daysAfterSalary: Int, categoryId: String) {
        self.intent = intent
        self.daysAfterSalary = daysAfterSalary
        self.categoryId = categoryId
    }
}
