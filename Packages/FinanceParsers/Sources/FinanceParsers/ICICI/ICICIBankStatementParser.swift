import Foundation

public struct ICICIBankStatementParser: InstitutionStatementParser {
    public let bankName = "ICICI"
    public let institutionVersion = "1.0"
    public let sourceType = StatementSourceType.bankAccount

    public init() {}

    public func canParse(rows: [[String]]) -> Bool {
        guard let firstRow = rows.first else { return false }
        guard let firstCell = firstRow.first else { return false }
        return firstCell.lowercased().contains("accountno")
    }

    public func parse(rows: [[String]]) throws -> ParsedStatement {
        guard rows.count > 1 else {
            throw TransactionImportError.malformedFile("ICICI statement too short")
        }

        let accountName = rows.count > 1 ? extractValue(rows[1]) : "Unknown"

        // Find header row dynamically by looking for "date" column
        var headerIndex = 0
        for (index, row) in rows.enumerated() {
            let normalized = row.map { $0.lowercased() }
            if normalized.contains(where: { $0.contains("date") }) {
                headerIndex = index
                break
            }
        }

        guard headerIndex < rows.count - 1 else {
            throw TransactionImportError.missingRequiredColumn("date")
        }

        let cardLast4: String? = nil
        let transactionRows = Array(rows.dropFirst(headerIndex))

        let currency = transactionRows.first.map(extractCurrencyFromHeaders) ?? "INR"
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

        let metadata = ICICIMetadataExtractor().extract(from: rows)

        return ParsedStatement(
            bankName: bankName,
            accountName: accountName,
            cardLast4: cardLast4,
            statementPeriodStart: periodStart,
            statementPeriodEnd: periodEnd,
            currency: currency,
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            transactions: transactions,
            metadata: metadata
        )
    }

    private func extractValue(_ row: [String]) -> String {
        guard row.count >= 2 else { return "Unknown" }
        return value(at: 1, in: row)
    }

    private func extractCardLast4(_ row: [String]) -> String? {
        guard let cardString = row.first else { return nil }
        let digits = String(cardString.filter(\.isNumber))
        guard digits.count >= 4 else { return nil }
        return String(digits.suffix(4))
    }

    private func value(at index: Int, in row: [String]) -> String {
        guard row.indices.contains(index) else {
            return ""
        }
        return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractCurrencyFromHeaders(_ headers: [String]) -> String {
        for header in headers {
            let upper = header.uppercased()
            if upper.contains("USD") {
                return "USD"
            } else if upper.contains("EUR") {
                return "EUR"
            } else if upper.contains("GBP") {
                return "GBP"
            } else if upper.contains("INR") || upper.contains("RS") {
                return "INR"
            }
        }
        return "INR"
    }
}
