import Foundation

/// Parses Axis Bank credit card statements in comma-delimited CSV format.
///
/// Detection signal: a row containing "Transaction Date" or "Date" plus "Description"
/// and either "Amount" or "Debit". Rows starting with "CLOSING" are excluded as footers.
public struct AxisCardCSVParser: Sendable {
    public init() {}

    /// Locates the column-header row, then collects all non-empty data rows until EOF.
    public func parse(fileURL: URL) throws -> [[String]] {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")

        var result: [[String]] = []
        var headerIndex = -1

        for (index, row) in rows.enumerated() {
            let normalized = row.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            if normalized.contains("transaction date") || normalized.contains("date") {
                if normalized.contains("description"),
                   normalized.contains("amount") || normalized.contains("debit") {
                    headerIndex = index
                    result.append(row)
                    break
                }
            }
        }

        guard headerIndex >= 0 else { return [] }

        for row in rows.dropFirst(headerIndex + 1) {
            guard row.count > 2 else { continue }
            let firstCol = row[0].trimmingCharacters(in: .whitespaces)
            if !firstCol.isEmpty, !firstCol.hasPrefix("CLOSING") {
                result.append(row)
            }
        }

        return result
    }

    public func canParse(fileURL: URL) throws -> Bool {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")

        for row in rows {
            let normalized = row.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            if normalized.contains("transaction date") || normalized.contains("date"),
               normalized.contains("description"),
               normalized.contains("amount") || normalized.contains("debit") {
                return true
            }
        }

        return false
    }
}
