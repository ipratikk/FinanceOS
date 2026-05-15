import Foundation

public struct ICICICardStatementParser: InstitutionStatementParser {
    public let bankName = "ICICI"
    public let sourceType = StatementSourceType.creditCard

    public init() {}

    public func canParse(rows: [[String]]) -> Bool {
        guard rows.count > 8 else { return false }

        let row6First = rows.count > 6 ? rows[6].first?.lowercased() ?? "" : ""
        let row1First = rows.count > 1 ? rows[1].first?.lowercased() ?? "" : ""

        return (row6First.contains("transaction") || row1First.contains("accountno"))
            && rows.count > 9
    }

    public func parse(rows: [[String]]) throws -> ParsedStatement {
        guard rows.count > 9 else {
            throw TransactionImportError.malformedFile("ICICI card statement too short")
        }

        let accountName = rows.count > 2 && rows[2].count > 1 ? rows[2][1]
            .trimmingCharacters(in: .whitespacesAndNewlines) : "Unknown"
        let cardLast4 = rows.count > 8 && !rows[8].isEmpty ? extractCardLast4(rows[8][0]) : nil
        let transactionRows = Array(rows.dropFirst(9))

        let currency = "INR"
        let transactions = try TabularTransactionDecoder.decodeTransactions(transactionRows)

        let (periodStart, periodEnd) = TabularTransactionDecoder.extractPeriod(from: transactions)

        var totalDebit: Int64 = 0
        var totalCredit: Int64 = 0

        for transaction in transactions {
            if transaction.amountMinorUnits < 0 {
                totalDebit -= transaction.amountMinorUnits
            } else {
                totalCredit += transaction.amountMinorUnits
            }
        }

        return ParsedStatement(
            bankName: bankName,
            accountName: accountName,
            cardLast4: cardLast4,
            statementPeriodStart: periodStart,
            statementPeriodEnd: periodEnd,
            currency: currency,
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            transactions: transactions
        )
    }

    private func extractCardLast4(_ cardString: String) -> String? {
        let digits = String(cardString.filter(\.isNumber))
        guard digits.count >= 4 else { return nil }
        return String(digits.suffix(4))
    }
}
