//
//  DefaultTransactionImporter.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public struct DefaultTransactionImporter:
    TransactionImporting,
    Sendable
{
    private let parsersByFormat: [StatementFileFormat: any StatementParser]
    private let registry: StatementParserRegistry

    public init(
        parsers: [any StatementParser] = [
            CSVStatementParser(),
            XLSXStatementParser()
        ],
        registry: StatementParserRegistry = StatementParserRegistry(
            parsers: [
                ICICIBankStatementParser(),
                ICICICardStatementParser(),
                HDFCBankStatementParser(),
                HDFCCardStatementParser(),
                AmexCardStatementParser()
            ]
        )
    ) {
        var parsersByFormat: [StatementFileFormat: any StatementParser] = [:]

        for parser in parsers {
            parsersByFormat[parser.supportedFormat] = parser
        }

        self.parsersByFormat = parsersByFormat
        self.registry = registry
    }

    public func parseStatement(
        from fileURL: URL,
        format: StatementFileFormat
    ) async throws -> ParsedStatement {
        guard let formatParser = parsersByFormat[format] else {
            throw TransactionImportError.unsupportedFormat(format)
        }

        // Extract rows using format parser
        let rows: [[String]]

        if let csvParser = formatParser as? CSVStatementParser {
            rows = try await csvParser.extractRows(from: fileURL)
        } else if let xlsxParser = formatParser as? XLSXStatementParser {
            rows = try await xlsxParser.extractRows(from: fileURL)
        } else {
            return try await formatParser.parseStatement(from: fileURL)
        }

        // Try institution parsers first
        if let institutionParser = registry.parser(for: rows) {
            return try institutionParser.parse(rows: rows)
        }

        // Fallback to generic decoder
        return try TabularTransactionDecoder.decodeStatement(rows)
    }

    public func importTransactions(
        from fileURL: URL,
        format: StatementFileFormat,
        target: TransactionImportTarget
    ) async throws -> [Transaction] {
        let statement = try await parseStatement(
            from: fileURL,
            format: format
        )

        return statement.transactions.map { parsedTransaction in
            let transactionType: TransactionType = parsedTransaction.amountMinorUnits >= 0 ? .credit : .debit
            let absoluteAmount = abs(parsedTransaction.amountMinorUnits)

            switch target {
            case let .account(accountID):
                return Transaction(
                    accountID: accountID,
                    postedAt: parsedTransaction.postedAt,
                    description: parsedTransaction.description,
                    amountMinorUnits: absoluteAmount,
                    currencyCode: parsedTransaction.currencyCode,
                    transactionType: transactionType,
                    sourceFingerprint: parsedTransaction.sourceFingerprint
                )

            case let .card(cardID):
                return Transaction(
                    cardID: cardID,
                    postedAt: parsedTransaction.postedAt,
                    description: parsedTransaction.description,
                    amountMinorUnits: absoluteAmount,
                    currencyCode: parsedTransaction.currencyCode,
                    transactionType: transactionType,
                    sourceFingerprint: parsedTransaction.sourceFingerprint
                )
            }
        }
    }
}
