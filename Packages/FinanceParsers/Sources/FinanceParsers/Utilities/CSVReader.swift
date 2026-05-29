import Foundation

/// Stateless utility for reading delimited text files into a two-dimensional array of strings.
/// For comma-delimited files it uses a RFC-4180-aware parser; other delimiters use a simple split.
public enum CSVReader {
    /// Reads all non-empty lines from `url` and splits them by `delimiter`.
    /// Comma-delimited files are parsed with quote-handling; other delimiters use a plain split.
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

    /// Parses one CSV line with double-quote escaping, returning `nil` for blank lines.
    /// Toggles `inQuotes` on each `"` character; commas inside quotes are part of the field value.
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
            } else if char == ",", !inQuotes {
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
