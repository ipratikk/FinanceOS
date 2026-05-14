import Foundation

public struct AmexCardStatementParser: InstitutionStatementParser {
    public let institution = "Amex"
    public let sourceType = StatementSourceType.creditCard

    public init() {}

    public func canParse(rows: [[String]]) -> Bool {
        guard rows.count > 1 else { return false }

        let headerRow = rows[0]
        guard headerRow.count >= 3 else { return false }

        let normalized = headerRow.map { $0.lowercased() }
        return normalized.contains(where: { $0.contains("date") }) &&
            normalized.contains(where: { $0.contains("description") }) &&
            normalized.contains(where: { $0.contains("amount") })
    }

    public func parse(rows: [[String]]) throws -> ParsedStatement {
        guard rows.count > 1 else {
            throw TransactionImportError.malformedFile("Amex statement too short")
        }

        let transactionRows = Array(rows.dropFirst(1))
        let transactions = try parseAmexTransactions(transactionRows)
        let (periodStart, periodEnd) = extractPeriod(from: transactions)

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
            accountName: "Unknown",
            cardLast4: nil,
            statementPeriodStart: periodStart,
            statementPeriodEnd: periodEnd,
            currency: "INR",
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            transactions: transactions
        )
    }

    private func parseAmexTransactions(_ rows: [[String]]) throws -> [ParsedTransaction] {
        var transactions: [ParsedTransaction] = []

        for row in rows {
            guard row.count >= 3 else { continue }

            guard let dateString = parseDate(row[0]) else { continue }

            let description = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !description.isEmpty else { continue }

            let amountStr = row[2].trimmingCharacters(in: .whitespacesAndNewlines)
            guard let amount = Decimal(string: amountStr) else { continue }

            let minorUnits = Int64(truncating: NSDecimalNumber(decimal: amount * 100))

            let fingerprint = [
                isoDateString(from: dateString),
                description,
                String(minorUnits),
                "INR"
            ].joined(separator: "|")

            transactions.append(
                ParsedTransaction(
                    postedAt: dateString,
                    description: description,
                    amountMinorUnits: minorUnits,
                    currencyCode: "INR",
                    sourceFingerprint: fingerprint,
                    rewardPoints: nil
                )
            )
        }

        return transactions
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            "MM/dd/yyyy",
            "MM/dd/yyyy HH:mm:ss"
        ].map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            return formatter
        }

        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }

    private func isoDateString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }

    private func extractPeriod(from transactions: [ParsedTransaction]) -> (Date?, Date?) {
        guard !transactions.isEmpty else { return (nil, nil) }
        let dates = transactions.map(\.postedAt).sorted()
        return (dates.first, dates.last)
    }
}
