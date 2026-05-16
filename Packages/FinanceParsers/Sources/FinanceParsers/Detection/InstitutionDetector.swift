import Foundation

public struct InstitutionDetector: Sendable {
    public static func detect(fileURL: URL, fileType: FileType) throws -> StatementSource {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        switch fileType {
        case .csv:
            return try detectCSV(lines: lines)
        case .txt:
            return try detectTXT(lines: lines)
        }
    }

    private static func detectCSV(lines: [String]) throws -> StatementSource {
        let text = lines.joined(separator: "\n").lowercased()

        if text.contains("~|~") && text.contains("card no:") {
            return .hdfcCard
        }

        for line in lines {
            let normalized = line.lowercased()
            if normalized.contains("billingamountsign") {
                return .iciciCard
            }
            if normalized.contains("particulars") &&
               normalized.contains("deposits") &&
               normalized.contains("withdrawals") {
                return .iciciBank
            }
            let cols = line.components(separatedBy: ",").map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            if cols.count == 3 &&
               cols.contains("date") &&
               cols.contains("description") &&
               cols.contains("amount") {
                return .amex
            }
        }

        throw DetectionError.unrecognizedFormat("CSV format not recognized")
    }

    private static func detectTXT(lines: [String]) throws -> StatementSource {
        let text = lines.joined(separator: "\n").lowercased()

        if text.contains("narration") && text.contains("closingbalance") {
            return .hdfcBank
        }

        throw DetectionError.unrecognizedFormat("TXT format not recognized")
    }
}
