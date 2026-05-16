import Foundation

public struct ICICICardCSVParser: Sendable {
    public init() {}

    public func parse(fileURL: URL) throws -> [[String]] {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")

        var headerIndex = -1
        for (index, row) in rows.enumerated() {
            let normalized = row.map { $0.lowercased() }
            if normalized.contains("date") && normalized.contains("billingamountsign") {
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
            if normalized.contains("billingamountsign") && normalized.contains("date") {
                return true
            }
        }

        return false
    }
}
