import Foundation

public struct AxisBankCSVParser: Sendable {
    public init() {}

    public func parse(fileURL: URL) throws -> [[String]] {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")

        var result: [[String]] = []
        var headerIndex = -1

        for (index, row) in rows.enumerated() {
            let normalized = row.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            if normalized.contains("tran. date") || normalized.contains("transaction date") {
                if normalized.contains("description"),
                   (normalized.contains("deposit") || normalized.contains("credit")),
                   (normalized.contains("withdrawal") || normalized.contains("debit"))
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
            let firstCol = row[0].trimmingCharacters(in: .whitespaces)
            if !firstCol.isEmpty && !firstCol.hasPrefix("CLOSING BALANCE") {
                result.append(row)
            }
        }

        return result
    }

    public func canParse(fileURL: URL) throws -> Bool {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")

        for row in rows {
            let normalized = row.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            if (normalized.contains("tran. date") || normalized.contains("transaction date")) &&
               normalized.contains("description") &&
               ((normalized.contains("deposit") || normalized.contains("credit")) ||
                (normalized.contains("withdrawal") || normalized.contains("debit")))
            {
                return true
            }
        }

        return false
    }
}
