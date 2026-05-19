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

        guard !storedWords.isEmpty, !parsedWords.isEmpty else { return false }

        let commonWords = Set(storedWords).intersection(Set(parsedWords))
        let requiredCommonWords = max(1, min(storedWords.count, parsedWords.count) - 1)
        return commonWords.count >= requiredCommonWords
    }

    /// Find best matching target for a parsed statement.
    /// Returns nil if no confident match exists (requiring user choice).
    /// Requires exact last4 match when available; does not fall back to "first at bank".
    public static func bestTarget(
        for statement: ParsedStatement,
        ledgers: [Ledger],
        banks: [Bank]
    ) -> TransactionImportTarget? {
        guard let match = bestMatch(for: statement, ledgers: ledgers, banks: banks) else {
            return nil
        }
        return match.confidence >= 0.9 ? match.target : nil
    }

    /// Find best matching target with confidence score.
    /// Returns nil if no potential match exists at all.
    public static func bestMatch(
        for statement: ParsedStatement,
        ledgers: [Ledger],
        banks: [Bank]
    ) -> ImportTargetMatch? {
        let isCard = statement.cardLast4 != nil
        let bankName = statement.bankName

        guard let bank = banks.first(where: { fuzzyMatch($0.name, bankName) }) else {
            return nil
        }

        if isCard, let cardLast4 = statement.cardLast4 {
            let banksCards = ledgers.filter { $0.bankId == bank.id && $0.kind == .creditCard }

            if let matchingCard = banksCards.first(where: { $0.last4 == cardLast4 }) {
                return ImportTargetMatch(.ledger(matchingCard.id), confidence: 1.0)
            }

            if banksCards.count == 1 {
                return ImportTargetMatch(.ledger(banksCards[0].id), confidence: 0.5)
            }

            return nil
        }

        if !isCard, let accountLast4 = statement.accountLast4 {
            let banksAccounts = ledgers.filter { $0.bankId == bank.id && $0.kind == .bankAccount }

            if let matchingAccount = banksAccounts.first(where: { $0.last4 == accountLast4 }) {
                return ImportTargetMatch(.ledger(matchingAccount.id), confidence: 1.0)
            }

            if banksAccounts.count == 1 {
                return ImportTargetMatch(.ledger(banksAccounts[0].id), confidence: 0.5)
            }

            return nil
        }

        if !isCard {
            let banksAccounts = ledgers.filter { $0.bankId == bank.id && $0.kind == .bankAccount }

            if banksAccounts.count == 1 {
                return ImportTargetMatch(.ledger(banksAccounts[0].id), confidence: 0.7)
            }

            return nil
        }

        return nil
    }
}
