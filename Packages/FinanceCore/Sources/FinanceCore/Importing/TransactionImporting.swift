//
//  TransactionImporting.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public protocol TransactionImporting: Sendable {
    func parseStatement(
        from fileURL: URL,
        format: StatementFileFormat
    ) async throws -> ParsedStatement

    func importTransactions(
        from fileURL: URL,
        format: StatementFileFormat,
        target: TransactionImportTarget
    ) async throws -> [Transaction]
}
