import Foundation

public struct HDFCBankTXTParser: Sendable {
    public init() {}

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

    private func reconstructRow(_ parts: [String]) -> [String] {
        guard parts.count >= 7 else { return parts }

        // Standard format: [date, narration, valueDate, debit, credit, ref, balance]
        // If narration contains commas, it becomes: [date, narr_part1, narr_part2..., valueDate, debit, credit, ref, balance]
        // Re-anchor by finding valueDate scanning backward from end

        let date = parts[0]

        // Try standard layout first: valueDate at index 2
        if parts.count >= 3, isDateString(parts[2]) {
            return parts
        }

        // Re-anchor: scan backward from end to find valueDate
        // Last 4 cols are: [debit, credit, ref, balance]
        guard parts.count > 4 else { return parts }

        var anchorIdx: Int? = nil
        for i in stride(from: parts.count - 4 - 1, through: 1, by: -1) {
            if isDateString(parts[i]) {
                anchorIdx = i
                break
            }
        }

        guard let anchor = anchorIdx else { return parts }

        // Reconstruct with correct column assignments
        var reconstructed = [String]()
        reconstructed.append(date)
        reconstructed.append(parts[1...anchor - 1].joined(separator: ","))
        reconstructed.append(parts[anchor])

        if anchor + 1 < parts.count { reconstructed.append(parts[anchor + 1]) } else { reconstructed.append("") }
        if anchor + 2 < parts.count { reconstructed.append(parts[anchor + 2]) } else { reconstructed.append("") }
        if anchor + 3 < parts.count { reconstructed.append(parts[anchor + 3]) } else { reconstructed.append("") }
        if anchor + 4 < parts.count { reconstructed.append(parts[anchor + 4]) } else { reconstructed.append("") }

        return reconstructed
    }

    public func parse(fileURL: URL) throws -> [[String]] {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
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
