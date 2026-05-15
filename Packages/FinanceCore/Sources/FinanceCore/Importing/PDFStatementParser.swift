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
        var currentBlock: [String] = []

        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let datePattern = "^\\d{2}/\\d{2}/\\d{2}"
            let isDateLine = trimmed.range(of: datePattern, options: .regularExpression) != nil

            if isDateLine, !currentBlock.isEmpty {
                if let txn = try parseTransactionBlock(currentBlock) {
                    transactions.append(txn)
                }
                currentBlock = [trimmed]
            } else if isDateLine {
                currentBlock = [trimmed]
            } else if !currentBlock.isEmpty {
                currentBlock.append(trimmed)
            }
        }

        if !currentBlock.isEmpty {
            if let txn = try parseTransactionBlock(currentBlock) {
                transactions.append(txn)
            }
        }

        return transactions
    }

    private func parseTransactionBlock(_ block: [String]) throws -> ParsedTransaction? {
        guard !block.isEmpty else { return nil }

        let fullText = block.joined(separator: " ")
        let datePattern = "^\\d{2}/\\d{2}/\\d{2}"
        guard let dateRange = fullText.range(of: datePattern, options: .regularExpression) else {
            return nil
        }

        let dateStr = String(fullText[dateRange])
        guard let postedAt = try? parseDate(dateStr) else { return nil }

        let afterDate = String(fullText[dateRange.upperBound...]).trimmingCharacters(in: .whitespaces)

        let amountPattern = "\\d{1,3}(,\\d{3})*\\.\\d{2}"
        var amounts: [String] = []

        if let regex = try? NSRegularExpression(pattern: amountPattern) {
            let nsRange = NSRange(afterDate.startIndex..., in: afterDate)
            let matches = regex.matches(in: afterDate, range: nsRange)
            for match in matches {
                if let range = Range(match.range, in: afterDate) {
                    amounts.append(String(afterDate[range]))
                }
            }
        }

        let descriptionText = amounts.isEmpty
            ? afterDate
            : {
                if let firstAmountRange = afterDate.range(of: amounts.first ?? "", options: .backwards) {
                    return String(afterDate[..<firstAmountRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                }
                return afterDate
            }()

        let description = descriptionText.isEmpty ? "HDFC Transaction" : descriptionText

        let amount: Int64
        if amounts.count >= 2 {
            let debitStr = amounts[amounts.count - 2]
            let creditStr = amounts[amounts.count - 1]
            let debit = try parseAmountMinorUnits(debitStr)
            let credit = try parseAmountMinorUnits(creditStr)

            if debit > 0, credit == 0 {
                amount = -debit
            } else if credit > 0, debit == 0 {
                amount = credit
            } else {
                amount = credit - debit
            }
        } else if amounts.count == 1 {
            let amountVal = try parseAmountMinorUnits(amounts[0])
            amount = amountVal
        } else {
            return nil
        }

        let fingerprint = [dateStr, description, String(amount)].joined(separator: "|")

        return ParsedTransaction(
            postedAt: postedAt,
            description: description,
            amountMinorUnits: amount,
            currencyCode: "INR",
            sourceFingerprint: fingerprint,
            rewardPoints: nil
        )
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
