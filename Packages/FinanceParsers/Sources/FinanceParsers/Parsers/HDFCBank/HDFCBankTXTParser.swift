import Foundation

public struct HDFCBankTXTParser: Sendable {
    public init() {}

    public func parse(fileURL: URL) throws -> [[String]] {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        var result: [[String]] = []
        var headerRow: [String]?

        for line in lines {
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }

            let row = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

            if headerRow == nil {
                let normalized = row.map { $0.lowercased() }
                if normalized.contains("narration") && normalized.contains("closingbalance") {
                    headerRow = row
                    result.append(row)
                    continue
                }
            }

            if headerRow != nil {
                result.append(row)
            }
        }

        return result
    }

    public func canParse(fileURL: URL) throws -> Bool {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let normalized = line.lowercased()
            if normalized.contains("narration") && normalized.contains("closingbalance") {
                return true
            }
        }

        return false
    }
}
