import Foundation

public struct HDFCCardStatementParser: InstitutionStatementParser {
    public let institution = "HDFC"
    public let sourceType = StatementSourceType.creditCard

    public init() {}

    public func canParse(rows: [[String]]) -> Bool {
        guard rows.count > 25 else { return false }

        let rawText = rows.map { $0.joined(separator: "") }.joined(separator: "\n")
        return rawText.contains("~|~") && rawText.contains("Card No:") && rawText.contains("DATE")
    }

    public func parse(rows: [[String]]) throws -> ParsedStatement {
        let rawText = rows.map { $0.joined(separator: "") }.joined(separator: "\n")
        let lines = rawText.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        guard lines.count > 26 else {
            throw TransactionImportError.malformedFile("HDFC card statement too short")
        }

        let accountName = extractAccountName(from: lines)
        let cardLast4 = extractCardLast4(from: lines)

        guard let transactionStartIdx = lines.firstIndex(where: { $0.contains("Domestic / International") }) else {
            throw TransactionImportError.malformedFile("Could not find transaction section")
        }

        let transactionLines = Array(lines.dropFirst(transactionStartIdx + 2))
        let currency = "INR"

        let transactions = try parseCardTransactions(transactionLines)
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

    private func extractAccountName(from lines: [String]) -> String {
        for line in lines.prefix(15) {
            if line.contains("Name~|~") {
                let parts = line.split(separator: "~|~")
                if parts.count > 1 {
                    return String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return "Unknown"
    }

    private func extractCardLast4(from lines: [String]) -> String? {
        for line in lines.prefix(25) {
            if line.contains("Card No:") {
                let digits = String(line.filter(\.isNumber))
                guard digits.count >= 4 else { continue }
                return String(digits.suffix(4))
            }
        }
        return nil
    }

    private func parseCardTransactions(_ lines: [String]) throws -> [ParsedTransaction] {
        var transactions: [ParsedTransaction] = []

        for line in lines {
            let fields = line.split(separator: "~|~").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            guard fields.count >= 6 else { continue }

            let trimmedFirst = fields[0]
            if trimmedFirst.isEmpty || trimmedFirst.contains("Reward") || trimmedFirst.contains("Points") {
                continue
            }

            guard let dateString = parseDate(fields[2]) else { continue }

            let description = fields[3]
            guard !description.isEmpty else { continue }

            let amountStr = fields[4].replacingOccurrences(of: ",", with: "")
            guard let amount = Decimal(string: amountStr) else { continue }

            let sign = fields.count > 5 ? fields[5].uppercased() : ""

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
