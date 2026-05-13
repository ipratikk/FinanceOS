//
//  TransactionImporting.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public protocol TransactionImporting {
    func importTransactions(
        from fileURL: URL,
        format: StatementFileFormat
    ) async throws -> [Transaction]
}
