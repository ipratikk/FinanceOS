import FinanceCore
import FinanceParsers
import Foundation

/// Preview/test data for parsed statements + transactions.
public enum PreviewStatements {
    public static func sampleParsedTransactions() -> [ParsedTransaction] {
        [
            ParsedTransaction(
                postedAt: Date(timeIntervalSince1970: 1_747_000_000),
                description: "Whole Foods Market",
                amountMinorUnits: 6543,
                currencyCode: "USD",
                sourceFingerprint: "tx1"
            ),
            ParsedTransaction(
                postedAt: Date(timeIntervalSince1970: 1_746_900_000),
                description: "Shell Gas Station",
                amountMinorUnits: 4215,
                currencyCode: "USD",
                sourceFingerprint: "tx2"
            ),
            ParsedTransaction(
                postedAt: Date(timeIntervalSince1970: 1_746_800_000),
                description: "Salary Deposit",
                amountMinorUnits: 500_000,
                currencyCode: "USD",
                sourceFingerprint: "tx3"
            )
        ]
    }

    public static func sampleStatement() -> ParsedStatement {
        ParsedStatement(
            bankName: "Chase",
            accountName: "Checking",
            accountLast4: "1234",
            statementPeriodStart: Date(timeIntervalSince1970: 1_746_000_000),
            statementPeriodEnd: Date(timeIntervalSince1970: 1_747_000_000),
            currency: "USD",
            totalDebit: 10758,
            totalCredit: 500_000,
            transactions: sampleParsedTransactions()
        )
    }
}
