import Foundation

public struct HDFCCardStatementParser: InstitutionStatementParser {
    public let institution = "HDFC"
    public let sourceType = StatementSourceType.creditCard

    public init() {}

    public func canParse(rows: [[String]]) -> Bool {
        guard rows.count > 25 else { return false }

        let hasCardNo = rows.count > 17 && (rows[17].first?.contains("Card No") ?? false)
        let hasAAN = rows.count > 19 && (rows[19].first?.contains("AAN") ?? false)
        let hasTransactionHeader = rows.count > 25 && (rows[25].first?.contains("Transactions") ?? false)

        return (hasCardNo || hasAAN) && hasTransactionHeader
    }

    public func parse(rows: [[String]]) throws -> ParsedStatement {
        guard rows.count > 26 else {
            throw TransactionImportError.malformedFile("HDFC card statement too short")
        }

        let accountName = extractAccountName(from: rows)
        let cardLast4 = extractCardLast4(from: rows)

        let transactionRows = Array(rows.dropFirst(27))
        let currency = "INR"

        let transactions = try parseCardTransactions(transactionRows)
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

    private func extractAccountName(from rows: [[String]]) -> String {
        guard rows.count > 1, let firstRow = rows.first else { return "Unknown" }
        guard firstRow.count > 1 else { return "Unknown" }

        return firstRow[1].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractCardLast4(from rows: [[String]]) -> String? {
        guard rows.count > 17 else { return nil }
        guard let cardLine = rows[17].first else { return nil }

        let digits = String(cardLine.filter(\.isNumber))
        guard digits.count >= 4 else { return nil }
        return String(digits.suffix(4))
    }

    private func parseCardTransactions(_ rows: [[String]]) throws -> [ParsedTransaction] {
        var transactions: [ParsedTransaction] = []

        for row in rows {
            guard row.count >= 6 else { continue }

            let trimmedFirst = row.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if trimmedFirst.isEmpty || trimmedFirst.contains("Reward Points") {
                continue
            }

            guard let dateString = parseDate(row[2]) else { continue }

            let description = row[3].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !description.isEmpty else { continue }

            let amountStr = row[4].trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(
                of: ",",
                with: ""
            )
            guard let amount = Decimal(string: amountStr) else { continue }

            let sign = row.count > 5 ? row[5].trimmingCharacters(in: .whitespacesAndNewlines).uppercased() : ""

            let minorUnits = Int64(truncating: NSDecimalNumber(decimal: amount * 100))
            let signedAmount = (sign == "CR") ? abs(minorUnits) : -abs(minorUnits)

            let fingerprint = [
                isoDateString(from: dateString),
                description,
                String(signedAmount),
                "INR"
            ].joined(separator: "|")

            transactions.append(
                ParsedTransaction(
                    postedAt: dateString,
                    description: description,
                    amountMinorUnits: signedAmount,
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
            "dd/MM/yyyy HH:mm:ss",
            "dd/MM/yyyy",
            "MM/dd/yyyy HH:mm:ss",
            "MM/dd/yyyy"
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
