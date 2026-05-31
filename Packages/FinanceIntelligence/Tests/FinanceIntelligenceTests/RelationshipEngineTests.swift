import Foundation
import Testing

@testable import FinanceIntelligence

@Suite("RelationshipEngine — behavioral signal inference")
struct RelationshipEngineTests {
    private let engine = RelationshipEngine()
    private let classifier = RelationshipClassifier()

    @Test("Monthly ₹22,000 round debit post-salary → landlord ≥ 0.70")
    func monthlyRentLandlord() {
        let salaryDate = Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 25))!
        let rentDate = Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 28))!
        let pattern = RecurringPattern(
            personId: "ritik", categoryId: "housing", intentId: "rent",
            cadence: .monthly, averageAmountMinorUnits: 2200000,
            confidence: 0.90, occurrenceCount: 6, lastSeenAt: rentDate
        )
        let transactions = (0..<6).map { i -> RelationshipEngine.TransactionRecord in
            let date = Calendar.current.date(byAdding: .month, value: -i, to: rentDate)!
            return RelationshipEngine.TransactionRecord(
                amount: 2200000, isDebit: true, postedAt: date,
                rawDescription: "UPI-RITIK GUPTA-rent", pattern: pattern
            )
        }
        let rel = engine.inferRelationship(
            personId: "ritik", personName: "Ritik Gupta",
            transactions: transactions, salaryCreditDates: [salaryDate]
        )
        #expect(rel?.type == .landlord)
        #expect((rel?.confidence ?? 0) >= 0.70)
    }

    @Test("UPI label with rent keyword → landlord signal")
    func upiLabelRentSignal() {
        let input = RelationshipClassifier.Input(
            personId: "p1", personName: "Seema Goel",
            totalDebits: 6_000_000, totalCredits: 0,
            transactionCount: 3, averageDebitAmount: 2_000_000,
            signals: [.recurringAmount, .roundNumber, .upiLabel],
            pattern: RecurringPattern(
                personId: "p1", categoryId: "housing", intentId: "rent",
                cadence: .monthly, averageAmountMinorUnits: 2_000_000,
                confidence: 0.85, occurrenceCount: 3, lastSeenAt: Date()
            )
        )
        let (type, confidence) = classifier.classify(input)
        #expect(type == .landlord)
        #expect(confidence >= 0.70)
    }

    @Test("Large recurring credits → employer")
    func recurringCreditsEmployer() {
        let transactions = (0..<12).map { _ in
            RelationshipEngine.TransactionRecord(
                amount: 15_000_000, isDebit: false,
                postedAt: Date(), rawDescription: "NEFT CR-PAYPAL SALARY"
            )
        }
        let rel = engine.inferRelationship(
            personId: "paypal", personName: "PayPal", transactions: transactions
        )
        #expect(rel?.type == .employer)
    }

    @Test("Small irregular transfers → friend or reimbursement")
    func smallIrregularFriend() {
        let transactions = (0..<3).map { _ in
            RelationshipEngine.TransactionRecord(
                amount: 50000, isDebit: true,
                postedAt: Date(), rawDescription: "UPI-AMAN PANDEY"
            )
        }
        let rel = engine.inferRelationship(
            personId: "aman", personName: "Aman Pandey", transactions: transactions
        )
        #expect(rel != nil)
        #expect([.friend, .reimbursement].contains(rel?.type))
    }

    @Test("Empty transactions → nil")
    func emptyNil() {
        #expect(engine.inferRelationship(personId: "x", personName: "X", transactions: []) == nil)
    }
}
