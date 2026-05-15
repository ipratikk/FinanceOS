import Foundation

public enum CSVRowReader {
    public static func read(from fileURL: URL) throws -> [[String]] {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        var rows: [[String]] = []
        for line in lines {
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            let row = line.components(separatedBy: ",")
            rows.append(row)
        }

        return rows
    }
}
