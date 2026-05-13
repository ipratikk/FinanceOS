//
//  StatementParser.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public protocol StatementParser: Sendable {
    var supportedFormat: StatementFileFormat { get }

    func parseStatement(
        from fileURL: URL
    ) async throws -> ParsedStatement
}
