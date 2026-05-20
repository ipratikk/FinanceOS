import Foundation

public struct ICICIBankCSVParser: Sendable {
    public init() {}

    public func parse(fileURL: URL) throws -> [[String]] {
        let rows = try CSVReader.readRows(from: fileURL, delimiter: ",")

        // Find all "Statement of Transactions in ..." section boundaries
        var sections: [(type: String, startIdx: Int)] = []
        for (idx, row) in rows.enumerated() {
            let first = row.first?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
            if first.contains("statement of transactions") {
                let joined = row.joined(separator: " ").lowercased()
                let sectionType = joined.contains("savings") ? "savings" :
                    joined.contains("ppf") ? "ppf" : "other"
                sections.append((type: sectionType, startIdx: idx))
            }
        }

        // Prefer Savings section; fall back to first section
        let target = sections.first { $0.type == "savings" } ?? sections.first
        guard let target else {
            // No section headers — fall back to scanning for column header
            return parseSingleSection(rows: rows, from: 0, to: rows.count)
        }

        let nextSectionIdx = sections.first { $0.startIdx > target.startIdx }?.startIdx ?? rows.count
        return parseSingleSection(rows: rows, from: target.startIdx, to: nextSectionIdx)
    }

    private func parseSingleSection(rows: [[String]], from start: Int, to end: Int) -> [[String]] {
        var result: [[String]] = []
        var headerIndex = -1

        for idx in start ..< end {
            let row = rows[idx]
            let firstCol = row.first?.uppercased().trimmingCharacters(in: .whitespaces) ?? ""
            if firstCol == "DATE" {
                let normalized = row.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                if normalized.contains("particulars"), normalized.contains("deposits"),
                   normalized.contains("withdrawals") {
                    headerIndex = idx
                    result.append(row)
                    break
                }
            }
        }

        guard headerIndex >= 0 else { return result }

        for idx in (headerIndex + 1) ..< end {
            let row = rows[idx]
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
               normalized.contains("withdrawals") {
                return true
            }
        }

        return false
    }
}
