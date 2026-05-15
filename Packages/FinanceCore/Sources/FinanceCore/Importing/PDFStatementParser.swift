//
//  PDFStatementParser.swift
//  FinanceCore
//
//  Created by Pratik Goel on 15/05/26.
//

import Foundation
import PDFKit

public struct PDFStatementParser: StatementParser, Sendable {
    public let supportedFormat: StatementFileFormat = .pdf
    private let password: String?

    public init(password: String? = nil) {
        self.password = password
    }

    public func parseStatement(from fileURL: URL) async throws -> ParsedStatement {
        guard let doc = PDFDocument(url: fileURL) else {
            throw TransactionImportError.malformedFile("Cannot open PDF")
        }

        if doc.isLocked {
            if let pwd = password {
                doc.unlock(withPassword: pwd)
            }
            if doc.isLocked {
                throw TransactionImportError.passwordProtected(fileURL.lastPathComponent)
            }
        }

        var fullText = ""
        for i in 0 ..< doc.pageCount {
            guard let page = doc.page(at: i),
                  let text = page.string
            else {
                continue
            }
            fullText += text + "\n"
        }

        let lines = fullText.components(separatedBy: .newlines)

        guard let headerIdx = lines.firstIndex(where: {
            $0.lowercased().contains("date") && $0.lowercased().contains("narration")
        }) else {
            throw TransactionImportError.malformedFile("No transaction table found in PDF")
        }

        let transactions = try parseHDFCPDFTransactions(Array(lines[headerIdx...]))
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

    private func parseHDFCPDFTransactions(_ lines: [String]) throws -> [ParsedTransaction] {
        var transactions: [ParsedTransaction] = []
        var currentTransaction: [String] = []

        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let datePattern = "^\\d{2}/\\d{2}/\\d{2}"
            if trimmed.range(of: datePattern, options: .regularExpression) != nil {
                if !currentTransaction.isEmpty {
                    let row = parseTransactionLine(currentTransaction.joined(separator: " "))
                    if !row.isEmpty {
                        try transactions.append(contentsOf: parseRowToTransaction(row))
                    }
                    currentTransaction = []
                }
                currentTransaction.append(trimmed)
            } else if !currentTransaction.isEmpty {
                currentTransaction.append(trimmed)
            }
        }

        if !currentTransaction.isEmpty {
            let row = parseTransactionLine(currentTransaction.joined(separator: " "))
            if !row.isEmpty {
                try transactions.append(contentsOf: parseRowToTransaction(row))
            }
        }

        return transactions
    }

    private func parseTransactionLine(_ line: String) -> [String] {
        let pattern = "^(\\d{2}/\\d{2}/\\d{2})\\s+(.+?)\\s+(\\d{2}/\\d{2}/\\d{2})\\s+([\\d,]+\\.\\d{2})?\\s+([\\d,]+\\.\\d{2})?\\s+([\\d,]+\\.\\d{2})$"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            if let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                var components: [String] = []
                for i in 1 ..< match.numberOfRanges {
                    if let range = Range(match.range(at: i), in: line) {
                        components.append(String(line[range]))
                    }
                }
                return components
            }
        }
        return []
    }

    private func parseRowToTransaction(_ components: [String]) throws -> [ParsedTransaction] {
        guard components.count >= 5 else { return [] }

        let dateStr = components[0]
        let description = components[1]
        let debitStr = components.count > 3 ? components[3] : ""
        let creditStr = components.count > 4 ? components[4] : ""

        guard let postedAt = try? parseDate(dateStr) else { return [] }

        let amount: Int64
        if !creditStr.isEmpty, !debitStr.isEmpty {
            let credit = try parseAmountMinorUnits(creditStr)
            let debit = try parseAmountMinorUnits(debitStr)
            amount = credit > 0 ? credit : -debit
        } else if !creditStr.isEmpty {
            amount = try parseAmountMinorUnits(creditStr)
        } else {
            amount = try parseAmountMinorUnits(debitStr)
        }

        let fingerprint = [
            dateStr,
            description.trimmingCharacters(in: .whitespaces),
            String(amount)
        ].joined(separator: "|")

        return [ParsedTransaction(
            postedAt: postedAt,
            description: description.trimmingCharacters(in: .whitespaces),
            amountMinorUnits: amount,
            currencyCode: "INR",
            sourceFingerprint: fingerprint,
            rewardPoints: nil
        )]
    }

    private func parseDate(_ value: String) throws -> Date {
        let formatters = [
            "dd/MM/yy",
            "dd/MM/yyyy"
        ].map { format -> DateFormatter in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            return formatter
        }

        for formatter in formatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }
        throw TransactionImportError.invalidDate(value)
    }

    private func parseAmountMinorUnits(_ value: String) throws -> Int64 {
        let sanitized = value
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let decimal = Decimal(string: sanitized) else {
            throw TransactionImportError.invalidAmount(value)
        }

        let minorUnitsDecimal = decimal * 100
        let rounded = NSDecimalNumber(decimal: minorUnitsDecimal).rounding(accordingToBehavior: nil)
        return rounded.int64Value
    }
}
