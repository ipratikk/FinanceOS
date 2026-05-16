@testable import FinanceCore
import FinanceParsers
import Foundation
import Testing

@Test
func mapperSignsDebitCorrectly() throws {
    let debitParsed = ParsedTransaction(
        postedAt: Date(),
        description: "ATM Withdrawal",
        amountMinorUnits: 50000,
        currencyCode: "INR",
        sourceFingerprint: "test|withdrawal|50000"
    )

    let accountID = UUID()
    let target = TransactionImportTarget.account(accountID)

    let mapped = ParsedTransactionMapper.map(debitParsed, target: target)

    #expect(mapped.transactionType == .debit)
    #expect(mapped.amountMinorUnits == 50000)
}

@Test
func mapperSignsCreditCorrectly() throws {
    let creditParsed = ParsedTransaction(
        postedAt: Date(),
        description: "Salary Deposit",
        amountMinorUnits: -100000,
        currencyCode: "INR",
        sourceFingerprint: "test|salary|-100000"
    )

    let accountID = UUID()
    let target = TransactionImportTarget.account(accountID)

    let mapped = ParsedTransactionMapper.map(creditParsed, target: target)

    #expect(mapped.transactionType == .credit)
    #expect(mapped.amountMinorUnits == 100000)
}

@Test
func mapperHandlesCardDebit() throws {
    let debitParsed = ParsedTransaction(
        postedAt: Date(),
        description: "Grocery Store",
        amountMinorUnits: 5000,
        currencyCode: "INR",
        sourceFingerprint: "test|grocery|5000"
    )

    let cardID = UUID()
    let target = TransactionImportTarget.card(cardID)

    let mapped = ParsedTransactionMapper.map(debitParsed, target: target)

    #expect(mapped.transactionType == .debit)
    #expect(mapped.amountMinorUnits == 5000)
    #expect(mapped.cardID == cardID)
}

@Test
func mapperHandlesCardCredit() throws {
    let creditParsed = ParsedTransaction(
        postedAt: Date(),
        description: "Payment Received",
        amountMinorUnits: -10000,
        currencyCode: "INR",
        sourceFingerprint: "test|payment|-10000"
    )

    let cardID = UUID()
    let target = TransactionImportTarget.card(cardID)

    let mapped = ParsedTransactionMapper.map(creditParsed, target: target)

    #expect(mapped.transactionType == .credit)
    #expect(mapped.amountMinorUnits == 10000)
    #expect(mapped.cardID == cardID)
}

@Test
func mapperPreservesSourceFingerprint() throws {
    let parsed = ParsedTransaction(
        postedAt: Date(),
        description: "Test",
        amountMinorUnits: 1000,
        currencyCode: "INR",
        sourceFingerprint: "20260501|Test|1000"
    )

    let target = TransactionImportTarget.account(UUID())
    let mapped = ParsedTransactionMapper.map(parsed, target: target)

    #expect(mapped.sourceFingerprint == "20260501|Test|1000")
}

@Test
func mapperPreservesDescription() throws {
    let description = "Amazon Purchase - Electronics"
    let parsed = ParsedTransaction(
        postedAt: Date(),
        description: description,
        amountMinorUnits: 25000,
        currencyCode: "INR",
        sourceFingerprint: "test|amazon|25000"
    )

    let target = TransactionImportTarget.account(UUID())
    let mapped = ParsedTransactionMapper.map(parsed, target: target)

    #expect(mapped.description == description)
}

@Test
func mapperHandlesZeroAmount() throws {
    let parsed = ParsedTransaction(
        postedAt: Date(),
        description: "Zero Transaction",
        amountMinorUnits: 0,
        currencyCode: "INR",
        sourceFingerprint: "test|zero|0"
    )

    let target = TransactionImportTarget.account(UUID())
    let mapped = ParsedTransactionMapper.map(parsed, target: target)

    #expect(mapped.transactionType == .debit)
    #expect(mapped.amountMinorUnits == 0)
}
