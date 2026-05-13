//
//  StatementParser.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public protocol StatementParser {
    var supportedFormat: StatementFileFormat { get }

    func parseTransactions(
        from fileURL: URL
    ) async throws -> [ParsedTransaction]
}
