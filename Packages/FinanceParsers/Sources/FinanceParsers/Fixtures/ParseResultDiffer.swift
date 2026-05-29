import Foundation

/// Compares two `ParseResult` values field-by-field and returns a list of human-readable
/// diff lines. An empty array means the results are equivalent for fixture purposes.
/// `id` fields on `ParsedTransaction` are intentionally excluded from comparison.
public enum ParseResultDiffer {
    /// Returns diff lines between `actual` and `expected`, or an empty array when they match.
    /// Returns an empty array when both are `nil`; one "One result is nil" line when only one is `nil`.
    public static func compare(_ actual: ParseResult?, _ expected: ParseResult?) -> [String] {
        var diffs: [String] = []

        guard let actual, let expected else {
            if actual == nil, expected == nil {
                return []
            }
            diffs.append("One result is nil")
            return diffs
        }

        if actual.schemaVersion != expected.schemaVersion {
            diffs.append("Schema version mismatch: \(actual.schemaVersion) vs \(expected.schemaVersion)")
        }

        if actual.institutionVersion != expected.institutionVersion {
            diffs.append("Institution version mismatch: \(actual.institutionVersion) vs \(expected.institutionVersion)")
        }

        diffs.append(contentsOf: compareStatements(actual.statement, expected.statement))

        return diffs
    }

    /// Compares statement-level fields and delegates transaction comparison to `compareTransactions`.
    private static func compareStatements(_ actual: ParsedStatement, _ expected: ParsedStatement) -> [String] {
        var diffs: [String] = []

        if actual.bankName != expected.bankName {
            diffs.append("Bank name: \(actual.bankName) vs \(expected.bankName)")
        }

        if actual.accountName != expected.accountName {
            diffs.append("Account name: \(actual.accountName) vs \(expected.accountName)")
        }

        if actual.cardLast4 != expected.cardLast4 {
            diffs.append("Card last 4: \(actual.cardLast4 ?? "nil") vs \(expected.cardLast4 ?? "nil")")
        }

        if actual.currency != expected.currency {
            diffs.append("Currency: \(actual.currency) vs \(expected.currency)")
        }

        if actual.transactions.count != expected.transactions.count {
            diffs.append("Transaction count: \(actual.transactions.count) vs \(expected.transactions.count)")
        }

        if actual.totalDebit != expected.totalDebit {
            diffs.append("Total debit: \(actual.totalDebit) vs \(expected.totalDebit)")
        }

        if actual.totalCredit != expected.totalCredit {
            diffs.append("Total credit: \(actual.totalCredit) vs \(expected.totalCredit)")
        }

        let transactionDiffs = compareTransactions(actual.transactions, expected.transactions)
        diffs.append(contentsOf: transactionDiffs)

        return diffs
    }

    /// Compares transactions positionally up to `min(actual.count, expected.count)`,
    /// then reports extra or missing transactions at the end.
    private static func compareTransactions(
        _ actual: [ParsedTransaction],
        _ expected: [ParsedTransaction]
    ) -> [String] {
        var diffs: [String] = []

        let minCount = min(actual.count, expected.count)
        for i in 0 ..< minCount {
            let actualTxn = actual[i]
            let expectedTxn = expected[i]

            if actualTxn.postedAt != expectedTxn.postedAt {
                diffs.append("Transaction \(i) date: \(actualTxn.postedAt) vs \(expectedTxn.postedAt)")
            }

            if actualTxn.description != expectedTxn.description {
                diffs.append("Transaction \(i) description: \(actualTxn.description) vs \(expectedTxn.description)")
            }

            if actualTxn.amountMinorUnits != expectedTxn.amountMinorUnits {
                diffs
                    .append("Transaction \(i) amount: \(actualTxn.amountMinorUnits) vs \(expectedTxn.amountMinorUnits)")
            }

            if actualTxn.currencyCode != expectedTxn.currencyCode {
                diffs.append("Transaction \(i) currency: \(actualTxn.currencyCode) vs \(expectedTxn.currencyCode)")
            }
        }

        if actual.count > expected.count {
            diffs.append("Extra \(actual.count - expected.count) transactions in actual")
        } else if expected.count > actual.count {
            diffs.append("Missing \(expected.count - actual.count) transactions in actual")
        }

        return diffs
    }
}
