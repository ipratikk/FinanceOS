//
//  DefaultTransactionImporter.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceParsers
import Foundation

public struct DefaultTransactionImporter:
    TransactionImporting,
    Sendable
{
    private let delegate: FinanceParsers.DefaultTransactionImporter

    public init(
        parsers: [any StatementParser]? = nil
    ) {
        delegate = FinanceParsers.DefaultTransactionImporter(parsers: parsers)
    }

    public func parseStatement(
        from fileURL: URL,
        format: StatementFileFormat
    ) async throws -> ParsedStatement {
        return try await delegate.parseStatement(from: fileURL, format: format)
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
            ParsedTransactionMapper.map(parsedTransaction, target: target)
        }
    }
}
