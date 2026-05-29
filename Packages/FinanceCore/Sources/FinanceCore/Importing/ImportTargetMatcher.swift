import FinanceParsers
import Foundation

/// A candidate import destination paired with a confidence score (0.0–1.0).
/// Used by `ImportTargetMatcher` and surfaced to the ImportViewModel for user confirmation.
public struct ImportTargetMatch {
    /// The ledger the statement should be imported into.
    public let target: TransactionImportTarget
    /// 1.0 = exact last4 match; 0.7 = sole ledger at bank; 0.5 = sole ledger (no last4).
    public let confidence: Double

    public init(_ target: TransactionImportTarget, confidence: Double) {
        self.target = target
        self.confidence = confidence
    }
}

/// Resolves a `ParsedStatement` to the most likely `TransactionImportTarget` using bank name
/// fuzzy-matching and card/account last-4 digit disambiguation.
public enum ImportTargetMatcher {
    /// Fuzzy match for institution names: requires either exact match or substantial word overlap.
    /// Prevents cross-bank false matches ("Bank" matching unrelated banks).
    public static func fuzzyMatch(_ stored: String, _ parsed: String) -> Bool {
        let storedLower = stored.lowercased()
        let parsedLower = parsed.lowercased()

        let storedWords = storedLower.split(separator: " ").map(String.init)
        let parsedWords = parsedLower.split(separator: " ").map(String.init)

        guard !storedWords.isEmpty, !parsedWords.isEmpty else { return false }

        let genericWords = Set(["bank", "credit", "card", "union"])

        // Reject if both inputs are single generic words (e.g., "Bank" vs "Bank")
        if storedWords.count == 1, parsedWords.count == 1, genericWords.contains(storedWords[0]) {
            return false
        }

        // Exact match (case-insensitive) - allowed for non-generic or multi-word strings
        if storedLower == parsedLower { return true }

        // If either string is a single word, it must match the first word and not be generic
        if storedWords.count == 1 {
            return !genericWords.contains(storedWords[0]) && storedWords[0] == parsedWords[0]
        }
        if parsedWords.count == 1 {
            return !genericWords.contains(parsedWords[0]) && parsedWords[0] == storedWords[0]
        }

        // For multi-word strings, require all non-generic words from shorter string to match longer
        let commonWords = Set(storedWords).intersection(Set(parsedWords)).subtracting(genericWords)
        let minNonGeneric = min(storedWords.count, parsedWords.count) - 1
        return commonWords.count >= max(1, minNonGeneric)
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
        return match.confidence >= 0.7 ? match.target : nil
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
