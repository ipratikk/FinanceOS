import Foundation

public struct HDFCCardCSVParser: Sendable {
    public init() {}

    public func parse(fileURL: URL) throws -> [[String]] {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        var result: [[String]] = []
        var collectingData = false
        var headerRow: [String]?

        for line in lines {
            if line.contains("Domestic / International") {
                collectingData = true
                continue
            }

            guard collectingData else { continue }

            let row = line.components(separatedBy: "~|~").map { $0.trimmingCharacters(in: .whitespaces) }

            if headerRow == nil && row.count > 0 && row[0].lowercased().contains("transaction") {
                headerRow = row
                result.append(row)
                continue
            }

            if headerRow != nil && row.count > 0 && !row[0].isEmpty {
                result.append(row)
            }
        }

        return result
    }

    public func canParse(fileURL: URL) throws -> Bool {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return content.contains("~|~") && content.contains("Card No:")
    }
}
