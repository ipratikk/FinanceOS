@testable import FinanceCore
import FinanceParsers
import Foundation
import GRDB
import Testing

// MARK: - Helpers

private struct MatcherDBSetup {
    let bankRepo: GRDBBankRepository
    let ledgerRepo: GRDBLedgerRepository
}

private func makeMatcherDB() throws -> MatcherDBSetup {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(in: &migrator)
    let dbQueue = try DatabaseQueue()
    try migrator.migrate(dbQueue)
    try dbQueue.write { database in try DatabaseSeeder.seedBanks(in: database) }
    return MatcherDBSetup(
        bankRepo: GRDBBankRepository(dbQueue: dbQueue),
        ledgerRepo: GRDBLedgerRepository(dbQueue: dbQueue)
    )
}

private func makeStatement(
    bankName: String,
    accountLast4: String? = nil,
    cardLast4: String? = nil
) -> ParsedStatement {
    ParsedStatement(
        bankName: bankName,
        accountName: bankName,
        accountLast4: accountLast4,
        cardLast4: cardLast4,
        transactions: [],
        metadata: nil
    )
}

// MARK: - ImportTargetMatcher: cross-bank same-last4

@Test
func importTargetMatcher_sameLast4DifferentBanks_matchesCorrectBank() {
    let hdfcBank = Bank(bank: .hdfc)
    let iciciBank = Bank(bank: .icici)

    let hdfcLedger = Ledger(bankId: hdfcBank.id, kind: .bankAccount, displayName: "HDFC", last4: "1234")
    let iciciLedger = Ledger(bankId: iciciBank.id, kind: .bankAccount, displayName: "ICICI", last4: "1234")

    let statement = makeStatement(bankName: "HDFC", accountLast4: "1234")
    let result = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: [hdfcLedger, iciciLedger],
        banks: [hdfcBank, iciciBank]
    )
    #expect(result == .ledger(hdfcLedger.id))
}

@Test
func importTargetMatcher_sameLast4DifferentBanks_iciciStatement_matchesICICI() {
    let hdfcBank = Bank(bank: .hdfc)
    let iciciBank = Bank(bank: .icici)

    let hdfcLedger = Ledger(bankId: hdfcBank.id, kind: .bankAccount, displayName: "HDFC", last4: "1234")
    let iciciLedger = Ledger(bankId: iciciBank.id, kind: .bankAccount, displayName: "ICICI", last4: "1234")

    let statement = makeStatement(bankName: "ICICI", accountLast4: "1234")
    let result = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: [hdfcLedger, iciciLedger],
        banks: [hdfcBank, iciciBank]
    )
    #expect(result == .ledger(iciciLedger.id))
}

@Test
func importTargetMatcher_unknownBank_returnsNil() {
    let hdfcBank = Bank(bank: .hdfc)
    let ledger = Ledger(bankId: hdfcBank.id, kind: .bankAccount, displayName: "HDFC", last4: "1234")

    let statement = makeStatement(bankName: "Unknown Bank", accountLast4: "1234")
    let result = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: [ledger],
        banks: [hdfcBank]
    )
    #expect(result == nil)
}

@Test
func importTargetMatcher_sameBankMultipleAccountsDifferentLast4_matchesCorrect() {
    let bank = Bank(bank: .hdfc)
    let ledger1 = Ledger(bankId: bank.id, kind: .bankAccount, displayName: "HDFC A", last4: "1111")
    let ledger2 = Ledger(bankId: bank.id, kind: .bankAccount, displayName: "HDFC B", last4: "2222")

    let statement = makeStatement(bankName: "HDFC", accountLast4: "2222")
    let result = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: [ledger1, ledger2],
        banks: [bank]
    )
    #expect(result == .ledger(ledger2.id))
}

@Test
func importTargetMatcher_sameBankMultipleCardsMatchesCorrect() {
    let bank = Bank(bank: .hdfc)
    let card1 = Ledger(bankId: bank.id, kind: .creditCard, displayName: "Regalia", last4: "1111")
    let card2 = Ledger(bankId: bank.id, kind: .creditCard, displayName: "MoneyBack", last4: "2222")

    let statement = makeStatement(bankName: "HDFC", cardLast4: "1111")
    let result = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: [card1, card2],
        banks: [bank]
    )
    #expect(result == .ledger(card1.id))
}

@Test
func importTargetMatcher_missingLast4NoSingleAccount_returnsNil() {
    let bank = Bank(bank: .hdfc)
    let ledger1 = Ledger(bankId: bank.id, kind: .bankAccount, displayName: "HDFC A", last4: "1111")
    let ledger2 = Ledger(bankId: bank.id, kind: .bankAccount, displayName: "HDFC B", last4: "2222")

    let statement = makeStatement(bankName: "HDFC", accountLast4: nil, cardLast4: nil)
    let result = ImportTargetMatcher.bestTarget(
        for: statement,
        ledgers: [ledger1, ledger2],
        banks: [bank]
    )
    #expect(result == nil)
}

// MARK: - AccountMatcher bank-aware exact match

@Test
@MainActor
func accountMatcher_exactMatch_requiresCorrectBank() async throws {
    let setup = try makeMatcherDB()
    let bankRepo = setup.bankRepo
    let ledgerRepo = setup.ledgerRepo

    let banks = try await bankRepo.fetchBanks()
    let hdfcBank = try #require(banks.first { $0.name == "HDFC Bank" })
    let iciciBank = try #require(banks.first { $0.name == "ICICI Bank" })

    let hdfcLedger = Ledger(bankId: hdfcBank.id, kind: .bankAccount, displayName: "HDFC Acc", last4: "9999")
    let iciciLedger = Ledger(bankId: iciciBank.id, kind: .bankAccount, displayName: "ICICI Acc", last4: "9999")
    try await ledgerRepo.insert(hdfcLedger)
    try await ledgerRepo.insert(iciciLedger)

    let matcher = AccountMatcher(ledgerRepository: ledgerRepo, bankRepository: bankRepo)

    let hdfcStatement = makeStatement(bankName: "HDFC Bank", accountLast4: "9999")
    let result = try await matcher.findMatches(for: hdfcStatement)

    if case let .exactMatch(ledger) = result {
        #expect(ledger.id == hdfcLedger.id)
        #expect(ledger.bankId == hdfcBank.id)
    } else {
        Issue.record("Expected exactMatch for HDFC statement, got \(result)")
    }
}

@Test
@MainActor
func accountMatcher_exactMatch_doesNotCrossBank() async throws {
    let setup = try makeMatcherDB()
    let bankRepo = setup.bankRepo
    let ledgerRepo = setup.ledgerRepo

    let banks = try await bankRepo.fetchBanks()
    let iciciBank = try #require(banks.first { $0.name == "ICICI Bank" })

    let iciciLedger = Ledger(bankId: iciciBank.id, kind: .bankAccount, displayName: "ICICI Acc", last4: "8888")
    try await ledgerRepo.insert(iciciLedger)

    let matcher = AccountMatcher(ledgerRepository: ledgerRepo, bankRepository: bankRepo)

    // Statement from HDFC, ledger belongs to ICICI — should NOT match
    let hdfcStatement = makeStatement(bankName: "HDFC Bank", accountLast4: "8888")
    let result = try await matcher.findMatches(for: hdfcStatement)

    if case .exactMatch = result {
        Issue.record("Should not exact-match ICICI ledger for HDFC statement")
    } else if case .fuzzyMatch = result {
        Issue.record("Should not fuzzy-match ICICI ledger for HDFC statement")
    }
    // noMatch is the expected outcome
}

@Test
@MainActor
func accountMatcher_noMatchWhenNoLedgers() async throws {
    let setup = try makeMatcherDB()
    let bankRepo = setup.bankRepo
    let ledgerRepo = setup.ledgerRepo
    let matcher = AccountMatcher(ledgerRepository: ledgerRepo, bankRepository: bankRepo)

    let statement = makeStatement(bankName: "HDFC Bank", accountLast4: "1234")
    let result = try await matcher.findMatches(for: statement)

    if case .noMatch = result {
        // expected
    } else {
        Issue.record("Expected noMatch when no ledgers exist, got \(result)")
    }
}
