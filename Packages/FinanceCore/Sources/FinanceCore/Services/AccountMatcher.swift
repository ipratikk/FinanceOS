import FinanceParsers
import Foundation

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
            bankName: targetBankName,
            last4: targetLast4,
            isCard: lookingForCard
        ) {
            return .exactMatch(exactMatch)
        }

        if let fuzzyMatch = findFuzzyMatch(
            ledgers: ledgers,
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

    private func findExactMatch(
        ledgers: [Ledger],
        bankName: String,
        last4: String?,
        isCard: Bool
    ) -> Ledger? {
        guard let last4 else { return nil }

        return ledgers.first { ledger in
            ledger.kind == (isCard ? .creditCard : .bankAccount) &&
                ledger.last4 == last4 &&
                ledger.bankId != nil
        }
    }

    private func findFuzzyMatch(
        ledgers: [Ledger],
        last4: String?,
        isCard: Bool
    ) -> Ledger? {
        guard let last4 else { return nil }

        return ledgers.first { ledger in
            ledger.kind == (isCard ? .creditCard : .bankAccount) &&
                ledger.last4 == last4
        }
    }

    private func findOrCreateBank(
        name: String,
        from banks: [Bank]
    ) -> Bank? {
        if let exact = banks.first(where: { $0.name == name }) {
            return exact
        }
        return nil
    }

    public enum AccountMatchResult: Sendable {
        case exactMatch(Ledger)
        case fuzzyMatch(Ledger)
        case noMatch(suggestedBank: Bank?)
    }
}
