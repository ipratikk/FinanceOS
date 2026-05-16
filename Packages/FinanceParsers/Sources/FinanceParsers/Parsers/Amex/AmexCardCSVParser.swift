import Foundation

public struct AmexCardCSVParser: Sendable {
    public init() {}

    public func parse(fileURL: URL) throws -> [[String]] {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")
        guard rows.count > 1 else { return [] }

        return rows
    }

    public func canParse(fileURL: URL) throws -> Bool {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")
        guard rows.count > 0 else { return false }

        let headerNormalized = rows[0].map { $0.lowercased() }
        return headerNormalized.count == 3 &&
               headerNormalized.contains("date") &&
               headerNormalized.contains("description") &&
               headerNormalized.contains("amount")
    }
}
