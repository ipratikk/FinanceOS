//
//  PDFStatementParser.swift
//  FinanceCore
//
//  Created by Pratik Goel on 15/05/26.
//

import Foundation
import OSLog
import PDFKit

private let logger = Logger(subsystem: "FinanceCore", category: "PDFParser")

public struct PDFStatementParser: StatementParser, Sendable {
    public let supportedFormat: StatementFileFormat = .pdf
    private let password: String?

    public init(password: String? = nil) {
        self.password = password
    }

    public func parseStatement(from fileURL: URL) async throws -> ParsedStatement {
        logger.debug("PDFStatementParser.parseStatement: opening PDF")
        guard let doc = PDFDocument(url: fileURL) else {
            logger.error("PDFStatementParser.parseStatement: Cannot open PDF")
            throw TransactionImportError.malformedFile("Cannot open PDF")
        }
        logger.debug("PDFStatementParser.parseStatement: PDF opened, checking if locked")

        if doc.isLocked {
            logger.debug("PDFStatementParser.parseStatement: PDF is locked")
            if let pwd = password {
                logger.debug("PDFStatementParser.parseStatement: attempting unlock with password")
                doc.unlock(withPassword: pwd)
            }
            if doc.isLocked {
                logger.error("PDFStatementParser.parseStatement: PDF still locked after unlock attempt")
                let filename = fileURL.lastPathComponent
                logger
                    .error(
                        "PDFStatementParser.parseStatement: throwing passwordProtected error for \(filename, privacy: .public)"
                    )
                throw TransactionImportError.passwordProtected(filename)
            }
        }
        logger.debug("PDFStatementParser.parseStatement: PDF unlocked, extracting text")

        var fullText = ""
        logger.debug("PDFStatementParser.parseStatement: page count = \(doc.pageCount)")
        for i in 0 ..< doc.pageCount {
            logger.debug("PDFStatementParser.parseStatement: extracting page \(i)")
            guard let page = doc.page(at: i),
                  let text = page.string
            else {
                logger.debug("PDFStatementParser.parseStatement: skipping page \(i)")
                continue
            }
            fullText += text + "\n"
        }
        logger.debug("PDFStatementParser.parseStatement: text extraction complete, splitting lines")

        let lines = fullText.components(separatedBy: .newlines)
        logger.debug("PDFStatementParser.parseStatement: lines count = \(lines.count)")

        guard let headerIdx = lines.firstIndex(where: {
            $0.lowercased().contains("date") && $0.lowercased().contains("narration")
        }) else {
            throw TransactionImportError.malformedFile("No transaction table found in PDF")
        }

        let transactions = try parseHDFCPDFTransactions(Array(lines[headerIdx...]))
        logger.debug("Parsed \(transactions.count) transactions from PDF")
        for (i, txn) in transactions.enumerated() {
            logger
                .debug(
                    "[\(i)] \(txn.postedAt, privacy: .public) | \(txn.description, privacy: .public) | \(txn.amountMinorUnits)"
                )
        }

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
        let classifier = HDFCLineClassifier()
        let reconstructor = HDFCTransactionReconstructor()
        let parser = HDFCTransactionParser()

        let classifiedLines = lines.map { classifier.classify($0) }
        let blocks = reconstructor.reconstructTransactionBlocks(from: classifiedLines)

        var transactions: [ParsedTransaction] = []

        for block in blocks {
            guard let rawTransaction = parser.parseTransactionBlock(block) else { continue }

            guard let postedAt = parser.validateDate(rawTransaction.dateString) else { continue }

            let description = rawTransaction.description.isEmpty ? "HDFC Transaction" : rawTransaction.description

            let amount: Int64
            if let debitStr = rawTransaction.debitAmount, let creditStr = rawTransaction.creditAmount {
                let debit = try parseAmountMinorUnits(debitStr)
                let credit = try parseAmountMinorUnits(creditStr)

                if debit > 0, credit == 0 {
                    amount = -debit
                } else if credit > 0, debit == 0 {
                    amount = credit
                } else {
                    amount = credit - debit
                }
            } else if let creditStr = rawTransaction.creditAmount {
                amount = try parseAmountMinorUnits(creditStr)
            } else if let debitStr = rawTransaction.debitAmount {
                amount = try -parseAmountMinorUnits(debitStr)
            } else {
                continue
            }

            let fingerprint = [rawTransaction.dateString, description, String(amount)].joined(separator: "|")

            let transaction = ParsedTransaction(
                postedAt: postedAt,
                description: description,
                amountMinorUnits: amount,
                currencyCode: "INR",
                sourceFingerprint: fingerprint,
                rewardPoints: nil
            )
            transactions.append(transaction)

            logger.debug(
                "Parsed [confidence: \(rawTransaction.confidence.overallConfidence, privacy: .public)] \(description, privacy: .public)"
            )
        }

        return transactions
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
