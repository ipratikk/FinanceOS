import Foundation

public struct ICICICardCSVParser: Sendable {
    public init() {}

    public func parse(fileURL: URL) throws -> [[String]] {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")
        guard rows.count > 2 else { return [] }

        return Array(rows.dropFirst(2))
    }

    public func canParse(fileURL: URL) throws -> Bool {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")
        guard rows.count > 1 else { return false }

        let headerNormalized = rows[1].map { $0.lowercased() }
        return headerNormalized.contains("billingamountsign")
    }
}
