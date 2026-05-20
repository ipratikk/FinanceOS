@testable import FinanceCore
import FinanceParsers
import Foundation
import Testing

let testBank = Bank(id: UUID(), bank: .hdfc)
let testBank2 = Bank(id: UUID(), bank: .icici)
let testBank3 = Bank(id: UUID(), bank: .amex)

let testLedger1 = Ledger(
    id: UUID(),
    bankId: testBank.id,
    kind: .bankAccount,
    displayName: "HDFC Account 1",
    last4: "6521"
)

let testLedger2 = Ledger(
    id: UUID(),
    bankId: testBank.id,
    kind: .bankAccount,
    displayName: "HDFC Account 2",
    last4: "9876"
)

let testLedger3 = Ledger(
    id: UUID(),
    bankId: testBank.id,
    kind: .creditCard,
    displayName: "HDFC Regalia",
    last4: "1234"
)

let testLedger4 = Ledger(
    id: UUID(),
    bankId: testBank.id,
    kind: .creditCard,
    displayName: "HDFC MoneyBack",
    last4: "5678"
)

// MARK: - FuzzyMatch Tests

@Test
func fuzzyMatchExactMatch() {
    #expect(ImportTargetMatcher.fuzzyMatch("HDFC", "HDFC"))
    #expect(ImportTargetMatcher.fuzzyMatch("ICICI Bank", "ICICI Bank"))
}

@Test
func fuzzyMatchCaseInsensitive() {
    #expect(ImportTargetMatcher.fuzzyMatch("HDFC", "hdfc"))
    #expect(ImportTargetMatcher.fuzzyMatch("Hdfc", "HDFC"))
}

@Test
func fuzzyMatchPartialWords() {
    #expect(ImportTargetMatcher.fuzzyMatch("HDFC Bank", "HDFC"))
    #expect(ImportTargetMatcher.fuzzyMatch("HDFC", "HDFC Bank"))
}

@Test
func fuzzyMatchRejectsCrossBankMatches() {
    #expect(!ImportTargetMatcher.fuzzyMatch("HDFC", "ICICI"))
    #expect(!ImportTargetMatcher.fuzzyMatch("HDFC Bank", "ICICI Bank"))
    #expect(!ImportTargetMatcher.fuzzyMatch("American Express", "Bank"))
}

@Test
func fuzzyMatchRejectsSingleCommonWord() {
    #expect(!ImportTargetMatcher.fuzzyMatch("HDFC Bank", "Bank"))
    #expect(!ImportTargetMatcher.fuzzyMatch("Bank", "Bank"))
}

// MARK: - BestTarget Tests

@Test
func bestTargetCardExactLast4Match() {
    let statement = ParsedStatement(
        bankName: "HDFC",
        accountName: "HDFC Card",
        accountLast4: nil,
        cardLast4: "1234",
        transactions: [],
        metadata: nil
    )

    let result = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: [testLedger1, testLedger2, testLedger3, testLedger4],
        banks: [testBank, testBank2, testBank3]
    )

    #expect(result == .ledger(testLedger3.id))
}

@Test
func bestTargetCardNoLast4MatchReturnsNil() {
    let statement = ParsedStatement(
        bankName: "HDFC",
        accountName: "HDFC Card",
        accountLast4: nil,
        cardLast4: "9999",
        transactions: [],
        metadata: nil
    )

    let result = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: [testLedger1, testLedger2, testLedger3, testLedger4],
        banks: [testBank, testBank2, testBank3]
    )

    #expect(result == nil)
}

@Test
func bestTargetCardMultipleCardsNoMatchReturnsNil() {
    let statement = ParsedStatement(
        bankName: "HDFC",
        accountName: "HDFC Card",
        accountLast4: nil,
        cardLast4: "1234",
        transactions: [],
        metadata: nil
    )

    let mismatchedLedger = Ledger(
        id: UUID(),
        bankId: testBank.id,
        kind: .creditCard,
        displayName: "HDFC Card",
        last4: "9999"
    )

    let result = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: [testLedger3, mismatchedLedger],
        banks: [testBank]
    )

    #expect(result == nil)
}

@Test
func bestTargetAccountExactLast4Match() {
    let statement = ParsedStatement(
        bankName: "HDFC",
        accountName: "HDFC Account",
        accountLast4: "6521",
        cardLast4: nil,
        transactions: [],
        metadata: nil
    )

    let result = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: [testLedger1, testLedger2, testLedger3, testLedger4],
        banks: [testBank, testBank2, testBank3]
    )

    #expect(result == .ledger(testLedger1.id))
}

@Test
func bestTargetAccountNoLast4MatchReturnsNil() {
    let statement = ParsedStatement(
        bankName: "HDFC",
        accountName: "HDFC Account",
        accountLast4: "9999",
        cardLast4: nil,
        transactions: [],
        metadata: nil
    )

    let result = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: [testLedger1, testLedger2, testLedger3, testLedger4],
        banks: [testBank, testBank2, testBank3]
    )

    #expect(result == nil)
}

@Test
func bestTargetAccountSingleAccount() {
    let statement = ParsedStatement(
        bankName: "HDFC",
        accountName: "HDFC Account",
        accountLast4: nil,
        cardLast4: nil,
        transactions: [],
        metadata: nil
    )

    let result = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: [testLedger1],
        banks: [testBank]
    )

    #expect(result == .ledger(testLedger1.id))
}

@Test
func bestTargetAccountMultipleAccountsNoLast4ReturnsNil() {
    let statement = ParsedStatement(
        bankName: "HDFC",
        accountName: "HDFC Account",
        accountLast4: nil,
        cardLast4: nil,
        transactions: [],
        metadata: nil
    )

    let result = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: [testLedger1, testLedger2],
        banks: [testBank]
    )

    #expect(result == nil)
}

@Test
func bestTargetBankNotFound() {
    let statement = ParsedStatement(
        bankName: "Unknown Bank",
        accountName: "Unknown Account",
        accountLast4: "1234",
        cardLast4: nil,
        transactions: [],
        metadata: nil
    )

    let result = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: [testLedger1],
        banks: [testBank, testBank2]
    )

    #expect(result == nil)
}

// MARK: - BestMatch Tests (with confidence)

@Test
func bestMatchReturnsConfidenceWithScore() {
    let statement = ParsedStatement(
        bankName: "HDFC",
        accountName: "HDFC Account",
        accountLast4: "6521",
        cardLast4: nil,
        transactions: [],
        metadata: nil
    )

    let result = ImportTargetMatcher.bestMatch(
        for: statement,
        ledgers: [testLedger1],
        banks: [testBank]
    )

    #expect(result?.target == .ledger(testLedger1.id))
    #expect(result?.confidence == 1.0)
}

@Test
func bestMatchPartialConfidenceForSingleAccountWithoutLast4() {
    let statement = ParsedStatement(
        bankName: "HDFC",
        accountName: "HDFC Account",
        accountLast4: nil,
        cardLast4: nil,
        transactions: [],
        metadata: nil
    )

    let result = ImportTargetMatcher.bestMatch(
        for: statement,
        ledgers: [testLedger1],
        banks: [testBank]
    )

    #expect(result?.target == .ledger(testLedger1.id))
    #expect(result?.confidence == 0.7)
}
