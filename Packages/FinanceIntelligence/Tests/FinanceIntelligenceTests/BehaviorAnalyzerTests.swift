@testable import FinanceIntelligence
import Foundation
import Testing

@Suite("BehaviorAnalyzer — salary cycle, cashflow, routine detection")
struct BehaviorAnalyzerTests {
    private let salaryAnalyzer = SalaryAnalyzer(minimumSalaryMinorUnits: 5_000_000)
    private let cashflowAnalyzer = CashflowAnalyzer()
    private let routineDetector = FinancialRoutineDetector()

    @Test("6-month salary fixture → cycle detected with confidence ≥ 0.80")
    func salaryCycleDetected() throws {
        let cal = Calendar.current
        let candidates = try (0 ..< 6).map { i -> SalaryAnalyzer.SalaryCandidate in
            let comps = DateComponents(year: 2025, month: 12 - i, day: 25)
            let date = try #require(cal.date(from: comps))
            return SalaryAnalyzer.SalaryCandidate(
                transactionId: UUID(), amount: 15_000_000,
                postedAt: date, categoryId: "income", intentId: "salary"
            )
        }
        let cycle = salaryAnalyzer.analyzeCycle(from: candidates)
        #expect(cycle != nil)
        #expect(cycle?.averageDayOfMonth == 25)
        #expect((cycle?.confidence ?? 0) >= 0.80)
        #expect(cycle?.sources.count == 6)
    }

    @Test("Single credit returns nil — minimum 2 months required")
    func singleCreditNil() {
        let candidate = SalaryAnalyzer.SalaryCandidate(
            transactionId: UUID(), amount: 15_000_000,
            postedAt: Date(), categoryId: "income", intentId: "salary"
        )
        #expect(salaryAnalyzer.analyzeCycle(from: [candidate]) == nil)
    }

    @Test("Below minimum amount not counted as salary")
    func belowMinimumExcluded() {
        let smallCredits = (0 ..< 6).map { _ in
            SalaryAnalyzer.SalaryCandidate(
                transactionId: UUID(), amount: 100_000,
                postedAt: Date(), categoryId: "income", intentId: "salary"
            )
        }
        #expect(salaryAnalyzer.analyzeCycle(from: smallCredits) == nil)
    }

    @Test("3 months of transactions → correct average income and expense")
    func cashflowAverages() throws {
        let cal = Calendar.current
        var records: [CashflowAnalyzer.TransactionRecord] = []
        for month in 1 ... 3 {
            let date = try #require(cal.date(from: DateComponents(year: 2025, month: month, day: 15)))
            records.append(.init(amount: 15_000_000, isDebit: false, postedAt: date))
            records.append(.init(amount: 8_000_000, isDebit: true, postedAt: date))
        }
        let summary = cashflowAnalyzer.analyze(transactions: records)
        #expect(summary.averageMonthlyIncome == 15_000_000)
        #expect(summary.averageMonthlyExpense == 8_000_000)
        let expectedRate = Double(15_000_000 - 8_000_000) / Double(15_000_000)
        #expect(abs(summary.savingsRate - expectedRate) < 0.001)
    }

    @Test("Positive savings rate when income > expense")
    func positiveSavingsRate() {
        let records: [CashflowAnalyzer.TransactionRecord] = [
            .init(amount: 10_000_000, isDebit: false, postedAt: Date()),
            .init(amount: 4_000_000, isDebit: true, postedAt: Date())
        ]
        let summary = cashflowAnalyzer.analyze(transactions: records)
        #expect(summary.savingsRate > 0)
        #expect(summary.savingsRate < 1)
    }

    @Test("Monthly snapshots grouped correctly by month")
    func monthlySnapshotsGrouped() throws {
        let cal = Calendar.current
        let jan = try #require(cal.date(from: DateComponents(year: 2025, month: 1, day: 25)))
        let feb = try #require(cal.date(from: DateComponents(year: 2025, month: 2, day: 25)))
        let records: [CashflowAnalyzer.TransactionRecord] = [
            .init(amount: 15_000_000, isDebit: false, postedAt: jan),
            .init(amount: 15_000_000, isDebit: false, postedAt: feb)
        ]
        let snapshots = cashflowAnalyzer.monthlySnapshots(from: records)
        #expect(snapshots.count == 2)
        #expect(snapshots.allSatisfy { $0.totalIncome == 15_000_000 })
    }

    @Test("Salary→rent within 7 days → routine detected with consistency ≥ 0.5")
    func salaryRentRoutineDetected() throws {
        let cal = Calendar.current
        var salaryCreditDates: [Date] = []
        var transactions: [FinancialRoutineDetector.TransactionRecord] = []
        for month in 1 ... 6 {
            let salaryDate = try #require(cal.date(from: DateComponents(year: 2025, month: month, day: 25)))
            salaryCreditDates.append(salaryDate)
            let rentDate = try #require(cal.date(byAdding: .day, value: 3, to: salaryDate))
            transactions.append(.init(
                amount: 2_200_000, isDebit: true,
                postedAt: rentDate, categoryId: "housing", intentId: "rent"
            ))
        }
        let routines = routineDetector.detect(
            salaryCreditDates: salaryCreditDates, transactions: transactions
        )
        #expect(!routines.isEmpty)
        #expect((routines.first?.consistency ?? 0) >= 0.5)
        let hasRentStep = routines.first?.steps.contains { $0.intent == "rent" } ?? false
        #expect(hasRentStep)
    }

    @Test("No salary dates → no routines detected")
    func emptySalaryDatesNoRoutines() {
        #expect(routineDetector.detect(salaryCreditDates: [], transactions: []).isEmpty)
    }

    @Test("BehaviorPattern savings rate computed correctly")
    func behaviorPatternSavingsRate() {
        let cashFlow = CashFlowSummary(
            averageMonthlyIncome: 15_000_000, averageMonthlyExpense: 10_000_000
        )
        let expected = Double(15_000_000 - 10_000_000) / Double(15_000_000)
        #expect(abs(cashFlow.savingsRate - expected) < 0.001)
    }
}
