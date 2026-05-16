import Foundation

public struct ICICIBankCSVParser: Sendable {
    public init() {}

    public func parse(fileURL: URL) throws -> [[String]] {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")

        var result: [[String]] = []
        var headerIndex = -1

        for (index, row) in rows.enumerated() {
            let firstCol = row.first?.uppercased() ?? ""
            if firstCol == "DATE" {
                let normalized = row.map { $0.lowercased() }
                if normalized.contains("particulars"), normalized.contains("deposits"),
                   normalized.contains("withdrawals")
                {
                    headerIndex = index
                    result.append(row)
                    break
                }
            }
        }

        guard headerIndex >= 0 else { return [] }

        for row in rows.dropFirst(headerIndex + 1) {
            guard row.count > 2 else { continue }
            let particulars = row[2].trimmingCharacters(in: .whitespaces)
            if !particulars.hasPrefix("B/F"), !particulars.isEmpty {
                result.append(row)
            }
        }

        return result
    }

    public func canParse(fileURL: URL) throws -> Bool {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")

        for row in rows {
            let normalized = row.map { $0.lowercased() }
            if normalized.contains("particulars"),
               normalized.contains("deposits"),
               normalized.contains("withdrawals")
            {
                return true
            }
        }

        return false
    }
}
