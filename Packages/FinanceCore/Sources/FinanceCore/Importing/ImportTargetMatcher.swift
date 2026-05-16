import FinanceParsers
import Foundation

public struct ImportTargetMatch {
    public let target: TransactionImportTarget
    public let confidence: Double

    public init(_ target: TransactionImportTarget, confidence: Double) {
        self.target = target
        self.confidence = confidence
    }
}

public enum ImportTargetMatcher {
    /// Fuzzy match for institution names: requires either exact match or substantial word overlap.
    /// Prevents cross-bank false matches ("Bank" matching unrelated banks).
    public static func fuzzyMatch(_ stored: String, _ parsed: String) -> Bool {
        let storedLower = stored.lowercased()
        let parsedLower = parsed.lowercased()

        if storedLower == parsedLower { return true }

        let storedWords = storedLower.split(separator: " ").map(String.init)
        let parsedWords = parsedLower.split(separator: " ").map(String.init)

        guard !storedWords.isEmpty && !parsedWords.isEmpty else { return false }

        let commonWords = Set(storedWords).intersection(Set(parsedWords))
        let requiredCommonWords = max(1, min(storedWords.count, parsedWords.count) - 1)
        return commonWords.count >= requiredCommonWords
    }

    /// Find best matching target for a parsed statement.
    /// Returns nil if no confident match exists (requiring user choice).
    /// Requires exact last4 match when available; does not fall back to "first at bank".
    public static func bestTarget(
        for statement: ParsedStatement,
        accounts: [Account],
        cards: [Card],
        banks: [Bank]
    ) -> TransactionImportTarget? {
        guard let match = bestMatch(for: statement, accounts: accounts, cards: cards, banks: banks) else {
            return nil
        }
        return match.confidence >= 0.9 ? match.target : nil
    }

    /// Find best matching target with confidence score.
    /// Returns nil if no potential match exists at all.
    public static func bestMatch(
        for statement: ParsedStatement,
        accounts: [Account],
        cards: [Card],
        banks: [Bank]
    ) -> ImportTargetMatch? {
        let isCard = statement.cardLast4 != nil
        let bankName = statement.bankName

        guard let bank = banks.first(where: { fuzzyMatch($0.name, bankName) }) else {
            return nil
        }

        if isCard, let cardLast4 = statement.cardLast4 {
            let banksCards = cards.filter { $0.bankId == bank.id }

            if let matchingCard = banksCards.first(where: { $0.cardLast4 == cardLast4 }) {
                return ImportTargetMatch(.card(matchingCard.id), confidence: 1.0)
            }

            if banksCards.count == 1 {
                return ImportTargetMatch(.card(banksCards[0].id), confidence: 0.5)
            }

            return nil
        }

        if !isCard, let accountLast4 = statement.accountLast4 {
            let banksAccounts = accounts.filter { $0.bankId == bank.id }

            if let matchingAccount = banksAccounts.first(where: { $0.accountLast4 == accountLast4 }) {
                return ImportTargetMatch(.account(matchingAccount.id), confidence: 1.0)
            }

            if banksAccounts.count == 1 {
                return ImportTargetMatch(.account(banksAccounts[0].id), confidence: 0.5)
            }

            return nil
        }

        if !isCard {
            let banksAccounts = accounts.filter { $0.bankId == bank.id }

            if banksAccounts.count == 1 {
                return ImportTargetMatch(.account(banksAccounts[0].id), confidence: 0.7)
            }

            return nil
        }

        return nil
    }
}
