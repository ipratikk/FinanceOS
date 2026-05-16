import Foundation

public struct TXTStatementParser: StatementParser, Sendable {
    public let supportedFormat: StatementFileFormat = .txt

    public init() {}

    public func parseStatement(from fileURL: URL) async throws -> ParsedStatement {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        var rows: [[String]] = []
        for line in lines {
            if rows.isEmpty, line.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }
            let fields = line.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            rows.append(fields)
        }

        guard rows.count > 1 else {
            throw TransactionImportError.malformedFile("TXT statement has no data rows")
        }

        let normalizedHeaders = rows[0].map(normalizeHeader(_:))
        guard normalizedHeaders.contains("debitamount") || normalizedHeaders.contains("creditamount") else {
            throw TransactionImportError.malformedFile("Unrecognized TXT format")
        }

        let transactions = try TabularTransactionDecoder.decodeTransactions(rows)
        let (periodStart, periodEnd) = TabularTransactionDecoder.extractPeriod(from: transactions)
        var totalDebit: Int64 = 0
        var totalCredit: Int64 = 0
        for txn in transactions {
            if txn.amountMinorUnits < 0 {
                totalDebit -= txn.amountMinorUnits
            } else {
                totalCredit += txn.amountMinorUnits
            }
        }
        return ParsedStatement(
            bankName: "HDFC",
            accountName: "Unknown",
            statementPeriodStart: periodStart,
            statementPeriodEnd: periodEnd,
            currency: "INR",
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            transactions: transactions
        )
    }

    private func normalizeHeader(_ h: String) -> String {
        h.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
    }
}
