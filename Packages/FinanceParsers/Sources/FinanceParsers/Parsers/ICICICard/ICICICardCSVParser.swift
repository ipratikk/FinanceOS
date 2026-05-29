import Foundation

/// Parses ICICI credit card statements in comma-delimited CSV format.
///
/// Detection signal: a row containing both "Date" and "BillingAmountSign" (case-insensitive).
/// Data rows start immediately after the detected header row.
public struct ICICICardCSVParser: Sendable {
    public init() {}

    /// Scans rows until the header is found, then returns all subsequent rows including the header.
    public func parse(fileURL: URL) throws -> [[String]] {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")

        var headerIndex = -1
        for (index, row) in rows.enumerated() {
            let normalized = row.map { $0.lowercased() }
            if normalized.contains("date"), normalized.contains("billingamountsign") {
                headerIndex = index
                break
            }
        }

        guard headerIndex >= 0 else { return [] }
        return Array(rows.dropFirst(headerIndex))
    }

    public func canParse(fileURL: URL) throws -> Bool {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")

        for row in rows {
            let normalized = row.map { $0.lowercased() }
            if normalized.contains("billingamountsign"), normalized.contains("date") {
                return true
            }
        }

        return false
    }
}
