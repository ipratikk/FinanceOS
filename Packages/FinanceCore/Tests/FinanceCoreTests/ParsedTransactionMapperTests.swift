@testable import FinanceCore
import FinanceParsers
import Foundation
import Testing

@Test
func mapperSignsDebitCorrectly() {
    let debitParsed = ParsedTransaction(
        postedAt: Date(),
        description: "ATM Withdrawal",
        amountMinorUnits: 50000,
        currencyCode: "INR",
        sourceFingerprint: "test|withdrawal|50000"
    )

    let ledgerId = UUID()
    let target = TransactionImportTarget.ledger(ledgerId)

    let mapped = ParsedTransactionMapper.map(debitParsed, target: target, ledgerKind: .bankAccount)

    #expect(mapped.transactionType == .debit)
    #expect(mapped.amountMinorUnits == 50000)
}

@Test
func mapperSignsCreditCorrectly() {
    let creditParsed = ParsedTransaction(
        postedAt: Date(),
        description: "Salary Deposit",
        amountMinorUnits: -100_000,
        currencyCode: "INR",
        sourceFingerprint: "test|salary|-100000"
    )

    let accountID = UUID()
    let target = TransactionImportTarget.ledger(accountID)

    let mapped = ParsedTransactionMapper.map(creditParsed, target: target, ledgerKind: .bankAccount)

    #expect(mapped.transactionType == .credit)
    #expect(mapped.amountMinorUnits == 100_000)
}

@Test
func mapperHandlesCardDebit() {
    let debitParsed = ParsedTransaction(
        postedAt: Date(),
        description: "Grocery Store",
        amountMinorUnits: 5000,
        currencyCode: "INR",
        sourceFingerprint: "test|grocery|5000"
    )

    let ledgerId = UUID()
    let target = TransactionImportTarget.ledger(ledgerId)

    let mapped = ParsedTransactionMapper.map(debitParsed, target: target, ledgerKind: .bankAccount)

    #expect(mapped.transactionType == .debit)
    #expect(mapped.amountMinorUnits == 5000)
    #expect(mapped.ledgerId == ledgerId)
}

@Test
func mapperHandlesCardCredit() {
    let creditParsed = ParsedTransaction(
        postedAt: Date(),
        description: "Payment Received",
        amountMinorUnits: -10000,
        currencyCode: "INR",
        sourceFingerprint: "test|payment|-10000"
    )

    let cardID = UUID()
    let target = TransactionImportTarget.ledger(cardID)

    let mapped = ParsedTransactionMapper.map(creditParsed, target: target, ledgerKind: .bankAccount)

    #expect(mapped.transactionType == .credit)
    #expect(mapped.amountMinorUnits == 10000)
    #expect(mapped.ledgerId == cardID)
}

@Test
func mapperPreservesSourceFingerprint() {
    let parsed = ParsedTransaction(
        postedAt: Date(),
        description: "Test",
        amountMinorUnits: 1000,
        currencyCode: "INR",
        sourceFingerprint: "20260501|Test|1000"
    )

    let target = TransactionImportTarget.ledger(UUID())
    let mapped = ParsedTransactionMapper.map(parsed, target: target, ledgerKind: .bankAccount)

    #expect(mapped.sourceFingerprint == "20260501|Test|1000")
}

@Test
func mapperPreservesDescription() {
    let description = "Amazon Purchase - Electronics"
    let parsed = ParsedTransaction(
        postedAt: Date(),
        description: description,
        amountMinorUnits: 25000,
        currencyCode: "INR",
        sourceFingerprint: "test|amazon|25000"
    )

    let target = TransactionImportTarget.ledger(UUID())
    let mapped = ParsedTransactionMapper.map(parsed, target: target, ledgerKind: .bankAccount)

    #expect(mapped.description == description)
}

@Test
func mapperHandlesZeroAmount() {
    let parsed = ParsedTransaction(
        postedAt: Date(),
        description: "Zero Transaction",
        amountMinorUnits: 0,
        currencyCode: "INR",
        sourceFingerprint: "test|zero|0"
    )

    let target = TransactionImportTarget.ledger(UUID())
    let mapped = ParsedTransactionMapper.map(parsed, target: target, ledgerKind: .bankAccount)

    #expect(mapped.transactionType == .debit)
    #expect(mapped.amountMinorUnits == 0)
}
