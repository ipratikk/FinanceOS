import Foundation

public struct HDFCBankStatementParser: InstitutionStatementParser {
    public let institution = "HDFC"
    public let sourceType = StatementSourceType.bankAccount

    public init() {}

    public func canParse(rows: [[String]]) -> Bool {
        guard rows.count > 2 else { return false }

        let headerRow = rows[1]
        let normalizedHeaders = headerRow.map(normalizeHeader)

        let hasDebit = normalizedHeaders.contains("debitamount")
        let hasCredit = normalizedHeaders.contains("creditamount")

        return hasDebit && hasCredit
    }

    public func parse(rows: [[String]]) throws -> ParsedStatement {
        guard rows.count > 2 else {
            throw TransactionImportError.malformedFile("HDFC statement too short")
        }

        let accountName = "Unknown"
        let cardLast4: String? = nil
        let transactionRows = Array(rows.dropFirst(2))

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
            institution: institution,
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

    private func normalizeHeader(_ header: String) -> String {
        header
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
    }
}
