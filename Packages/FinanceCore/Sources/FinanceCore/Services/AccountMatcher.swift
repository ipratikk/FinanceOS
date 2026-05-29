import FinanceParsers
import Foundation

/// Resolves a parsed bank statement to an existing ledger in the app using exact or fuzzy matching.
/// Sits between the import pipeline and the UI's account-selection step; never writes to persistence.
@MainActor
public final class AccountMatcher {
    private let ledgerRepository: any LedgerRepository
    private let bankRepository: any BankRepository

    public init(
        ledgerRepository: any LedgerRepository,
        bankRepository: any BankRepository
    ) {
        self.ledgerRepository = ledgerRepository
        self.bankRepository = bankRepository
    }

    /// Attempts to match `statement` to a known ledger, falling back to a suggested bank on failure.
    public func findMatches(
        for statement: ParsedStatement
    ) async throws -> AccountMatchResult {
        let ledgers = try await ledgerRepository.fetchLedgers()
        let banks = try await bankRepository.fetchBanks()

        let lookingForCard = statement.cardLast4 != nil
        let targetLast4 = statement.cardLast4 ?? statement.accountLast4
        let targetBankName = statement.bankName

        if let exactMatch = findExactMatch(
            ledgers: ledgers,
            banks: banks,
            bankName: targetBankName,
            last4: targetLast4,
            isCard: lookingForCard
        ) {
            return .exactMatch(exactMatch)
        }

        if let fuzzyMatch = findFuzzyMatch(
            ledgers: ledgers,
            banks: banks,
            bankName: targetBankName,
            last4: targetLast4,
            isCard: lookingForCard
        ) {
            return .fuzzyMatch(fuzzyMatch)
        }

        let suggestedBank = findOrCreateBank(
            name: targetBankName,
            from: banks
        )

        return .noMatch(suggestedBank: suggestedBank)
    }

    /// Matches bank name (fuzzy) + last-4 + account kind — all three must agree.
    private func findExactMatch(
        ledgers: [Ledger],
        banks: [Bank],
        bankName: String,
        last4: String?,
        isCard: Bool
    ) -> Ledger? {
        guard let last4 else { return nil }
        guard let matchingBank = banks.first(where: {
            ImportTargetMatcher.fuzzyMatch($0.name, bankName)
        }) else { return nil }

        return ledgers.first { ledger in
            ledger.kind == (isCard ? .creditCard : .bankAccount) &&
                ledger.last4 == last4 &&
                ledger.bankId == matchingBank.id
        }
    }

    /// Same logic as `findExactMatch`; retained as a separate step to allow diverging heuristics later.
    private func findFuzzyMatch(
        ledgers: [Ledger],
        banks: [Bank],
        bankName: String,
        last4: String?,
        isCard: Bool
    ) -> Ledger? {
        guard let last4 else { return nil }
        guard let matchingBank = banks.first(where: {
            ImportTargetMatcher.fuzzyMatch($0.name, bankName)
        }) else { return nil }

        return ledgers.first { ledger in
            ledger.kind == (isCard ? .creditCard : .bankAccount) &&
                ledger.last4 == last4 &&
                ledger.bankId == matchingBank.id
        }
    }

    /// Returns the exact-name bank if already known; UI uses this as the pre-filled suggestion when creating a ledger.
    private func findOrCreateBank(
        name: String,
        from banks: [Bank]
    ) -> Bank? {
        if let exact = banks.first(where: { $0.name == name }) {
            return exact
        }
        return nil
    }

    /// Outcome of a single statement-to-ledger resolution attempt.
    public enum AccountMatchResult: Sendable {
        /// Statement metadata (bank + last-4 + kind) matched an existing ledger unambiguously.
        case exactMatch(Ledger)
        /// A probable match was found but confidence is lower — user should confirm.
        case fuzzyMatch(Ledger)
        /// No ledger found; `suggestedBank` pre-fills the new-ledger form if available.
        case noMatch(suggestedBank: Bank?)
    }
}
