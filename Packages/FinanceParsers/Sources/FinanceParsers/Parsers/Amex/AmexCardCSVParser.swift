import Foundation

/// Parses American Express card statements in minimal 3-column CSV format.
///
/// Detection signal: exactly 3 columns — "Date", "Description", "Amount" — in the first row.
/// The file has no metadata header block; the first row is the column header.
public struct AmexCardCSVParser: Sendable {
    public init() {}

    /// Returns all rows as-is (first row is the header); rejects files with fewer than 2 rows.
    public func parse(fileURL: URL) throws -> [[String]] {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")
        guard rows.count > 1 else { return [] }

        return rows
    }

    public func canParse(fileURL: URL) throws -> Bool {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")
        guard !rows.isEmpty else { return false }

        let headerNormalized = rows[0].map { $0.lowercased() }
        return headerNormalized.count == 3 &&
            headerNormalized.contains("date") &&
            headerNormalized.contains("description") &&
            headerNormalized.contains("amount")
    }
}
