import FinanceParsers
import Foundation

public enum ImportTargetMatcher {
    public static func fuzzyMatch(_ stored: String, _ parsed: String) -> Bool {
        let storedLower = stored.lowercased()
        let parsedLower = parsed.lowercased()

        if storedLower == parsedLower { return true }
        if storedLower.contains(parsedLower) || parsedLower.contains(storedLower) { return true }

        let storedWords = storedLower.split(separator: " ").map(String.init)
        let parsedWords = parsedLower.split(separator: " ").map(String.init)

        let commonWords = Set(storedWords).intersection(Set(parsedWords))
        return !commonWords.isEmpty && commonWords.count >= min(storedWords.count, parsedWords.count) / 2
    }

    public static func bestTarget(
        for statement: ParsedStatement,
        accounts: [Account],
        cards: [Card],
        banks: [Bank]
    ) -> TransactionImportTarget? {
        let isCard = statement.cardLast4 != nil
        let bankName = statement.bankName

        let matchingBank = banks.first { bank in
            fuzzyMatch(bank.name, bankName)
        }
        guard let bank = matchingBank else { return nil }

        if isCard, let cardLast4 = statement.cardLast4 {
            if let matchingCard = cards.first(where: { $0.bankId == bank.id && $0.cardLast4 == cardLast4 }) {
                return .card(matchingCard.id)
            } else if let matchingCard = cards.first(where: { $0.bankId == bank.id }) {
                return .card(matchingCard.id)
            }
        } else if !isCard, let accountLast4 = statement.accountLast4 {
            if let matchingAccount = accounts
                .first(where: { $0.bankId == bank.id && $0.accountLast4 == accountLast4 })
            {
                return .account(matchingAccount.id)
            } else if let matchingAccount = accounts.first(where: { $0.bankId == bank.id }) {
                return .account(matchingAccount.id)
            }
        } else if !isCard {
            if let matchingAccount = accounts.first(where: { $0.bankId == bank.id }) {
                return .account(matchingAccount.id)
            }
        }

        return nil
    }
}
