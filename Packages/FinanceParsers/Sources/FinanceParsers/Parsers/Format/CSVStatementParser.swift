import Foundation
import SwiftCSV

public struct CSVStatementParser: StatementParser, Sendable {
    public let supportedFormat: StatementFileFormat = .csv

    public init() {}

    public func parseStatement(
        from fileURL: URL
    ) async throws -> ParsedStatement {
        let rows = try await extractRows(from: fileURL)
        return try TabularTransactionDecoder.decodeStatement(rows)
    }

    func extractRows(from fileURL: URL) async throws -> [[String]] {
        let csv = try EnumeratedCSV(
            url: fileURL,
            loadColumns: false
        )
        return [csv.header] + csv.rows
    }
}
