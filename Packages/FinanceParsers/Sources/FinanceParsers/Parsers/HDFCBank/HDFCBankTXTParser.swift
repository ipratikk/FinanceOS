import Foundation

public struct HDFCBankTXTParser: Sendable {
    public init() {}

    // MARK: - Shared helpers

    private func parseDate(_ text: String) -> Date? {
        let formats = ["dd/MM/yy", "dd/MM/yyyy"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: text.trimmingCharacters(in: .whitespaces)) {
                return date
            }
        }
        return nil
    }

    private func isDateString(_ text: String) -> Bool {
        parseDate(text) != nil
    }

    // MARK: - Fixed-width detection

    private func isFixedWidth(_ content: String) -> Bool {
        content.components(separatedBy: .newlines).contains { line in
            line.hasPrefix("--------  ---")
        }
    }

    // MARK: - Fixed-width column range extraction

    func columnRanges(from separator: String) -> [(Int, Int)] {
        var ranges: [(Int, Int)] = []
        var inDash = false
        var start = 0
        for (i, ch) in separator.enumerated() {
            if ch == "-", !inDash { start = i; inDash = true } else if ch != "-", inDash {
                ranges.append((start, i)); inDash = false
            }
        }
        if inDash { ranges.append((start, separator.count)) }
        return ranges
    }

    func extractField(_ line: String, _ range: (Int, Int)) -> String {
        let chars = Array(line.unicodeScalars)
        let start = min(range.0, chars.count)
        let end = min(range.1, chars.count)
        guard start < end else { return "" }
        return String(String.UnicodeScalarView(chars[start ..< end])).trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Fixed-width parse

    private func parseFixedWidth(_ content: String) -> [[String]] {
        let lines = content.components(separatedBy: .newlines)
        guard let sepLine = lines.first(where: { $0.hasPrefix("--------  ---") }) else { return [] }
        let ranges = columnRanges(from: sepLine)
        guard ranges.count >= 7 else { return [] }

        let header = [
            "Date",
            "Narration",
            "Chq./Ref.No.",
            "Value Dt",
            "Withdrawal Amt.",
            "Deposit Amt.",
            "Closing Balance"
        ]
        var result: [[String]] = [header]
        var seenSeparatorCount = 0
        var pastData = false
        var pending: [String]?

        func flush() {
            if let row = pending { result.append(row); pending = nil }
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("**Continue**") || trimmed.contains("** Continue **") { continue }
            if line.hasPrefix("****") { break }
            if line.hasPrefix("--------  ---") {
                seenSeparatorCount += 1
                if seenSeparatorCount % 2 == 0 { pastData = true }
                continue
            }
            guard pastData, !trimmed.isEmpty else { continue }

            let dateField = extractField(line, ranges[0])
            if isDateString(dateField) {
                flush()
                pending = ranges.map { extractField(line, $0) }
            } else if dateField.isEmpty {
                appendContinuation(line, to: &pending, ranges: ranges)
            }
        }
        flush()
        return result
    }

    private func appendContinuation(_ line: String, to pending: inout [String]?, ranges: [(Int, Int)]) {
        guard var row = pending else { return }
        let cont = extractField(line, ranges[1])
        guard !cont.isEmpty else { return }
        row[1] = (row[1] + " " + cont).trimmingCharacters(in: .whitespaces)
        pending = row
    }

    // MARK: - Delimited helpers

    private func reconstructRow(_ parts: [String]) -> [String] {
        guard parts.count >= 7 else { return parts }
        let date = parts[0]
        if parts.count >= 3, isDateString(parts[2]) {
            return parts
        }
        guard parts.count > 4 else { return parts }
        var anchorIdx: Int?
        for i in stride(from: parts.count - 4 - 1, through: 1, by: -1) where isDateString(parts[i]) {
            anchorIdx = i
            break
        }
        guard let anchor = anchorIdx else { return parts }
        var reconstructed = [String]()
        reconstructed.append(date)
        reconstructed.append(parts[1 ... anchor - 1].joined(separator: ","))
        reconstructed.append(parts[anchor])
        if anchor + 1 < parts.count { reconstructed.append(parts[anchor + 1]) } else { reconstructed.append("") }
        if anchor + 2 < parts.count { reconstructed.append(parts[anchor + 2]) } else { reconstructed.append("") }
        if anchor + 3 < parts.count { reconstructed.append(parts[anchor + 3]) } else { reconstructed.append("") }
        if anchor + 4 < parts.count { reconstructed.append(parts[anchor + 4]) } else { reconstructed.append("") }
        return reconstructed
    }

    // MARK: - Public API

    public func parse(fileURL: URL) throws -> [[String]] {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        if isFixedWidth(content) {
            let rows = parseFixedWidth(content)
            if rows.count <= 1 { throw TransactionImportError.malformedFile("No data rows found") }
            return rows
        }
        return try parseDelimited(content: content)
    }

    private func parseDelimited(content: String) throws -> [[String]] {
        let lines = content.components(separatedBy: .newlines)
        var result: [[String]] = []
        var headerRow: [String]?

        for line in lines {
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            let rawParts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if headerRow == nil {
                let normalized = rawParts.map { $0.lowercased() }
                if normalized.contains("narration"), normalized.contains("closing balance") {
                    headerRow = rawParts
                    result.append(rawParts)
                    continue
                }
            }
            if headerRow != nil {
                let row = reconstructRow(rawParts)
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
            if normalized.contains("narration"), normalized.contains("closing balance") {
                return true
            }
        }
        return false
    }
}
