import Foundation

public enum CSVReader {
    public static func readRows(
        from url: URL,
        delimiter: String = ","
    ) throws -> [[String]] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        if delimiter == "," {
            return lines.compactMap { parseCSVLine($0) }
        } else {
            return lines.map { $0.components(separatedBy: delimiter).map { $0.trimmingCharacters(in: .whitespaces) } }
        }
    }

    private static func parseCSVLine(_ line: String) -> [String]? {
        guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }

        var result: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let char = line[i]

            if char == "\"" {
                inQuotes = !inQuotes
                i = line.index(after: i)
            } else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
                i = line.index(after: i)
            } else {
                current.append(char)
                i = line.index(after: i)
            }
        }

        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }
}
