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

        if doc.isEncrypted && !doc.isUnlocked {
            if let pwd = password {
                doc.unlock(withPassword: pwd)
            }
            if !doc.isUnlocked {
                throw TransactionImportError.passwordProtected(fileURL.lastPathComponent)
            }
        }

        var allLines: [String] = []
        for i in 0 ..< doc.pageCount {
            guard let page = doc.page(at: i),
                  let text = page.string
            else {
                continue
            }
            allLines += text.components(separatedBy: .newlines)
        }

        guard let headerIdx = allLines.firstIndex(where: {
            let n = $0.lowercased().replacingOccurrences(of: " ", with: "")
            return n.contains("date") && n.contains("narration")
        }) else {
            throw TransactionImportError.malformedFile("No transaction table found in PDF")
        }

        let tableLines = Array(allLines[headerIdx...])
        let rows = tableLines.compactMap(parseLineToRow(_:))

        guard rows.count > 1 else {
            throw TransactionImportError.malformedFile("PDF has no transaction rows")
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

    private func parseLineToRow(_ line: String) -> [String] {
        if line.contains("\t") {
            return line.components(separatedBy: "\t")
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.components(separatedBy: "  ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
