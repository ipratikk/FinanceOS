//
//  CSVStatementParser.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import SwiftCSV

public struct CSVStatementParser:
    StatementParser,
    Sendable
{
    public let supportedFormat: StatementFileFormat = .csv

    public init() {}

    public func parseStatement(
        from fileURL: URL
    ) async throws -> ParsedStatement {
        let csv = try EnumeratedCSV(
            url: fileURL,
            loadColumns: false
        )

        let rows = [csv.header] + csv.rows
        return try TabularTransactionDecoder.decodeStatement(rows)
    }
}
