import Foundation

/// Identifies which Indian bank institution issued a statement by scanning its content
/// for institution-specific header keywords and column patterns.
public struct InstitutionDetector: Sendable {
    /// Reads the file at `fileURL` and returns the matching `StatementSource`.
    /// Throws `DetectionError.unrecognizedFormat` when no known institution signature is found.
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

    /// Detects institution from CSV content using header keywords and column signatures.
    /// Heuristics: HDFC Card uses `~|~` delimiter; ICICI Card has `BillingAmountSign`;
    /// ICICI Bank has `Particulars`/`Deposits`/`Withdrawals`; Amex has exactly Date/Description/Amount.
    private static func detectCSV(lines: [String]) throws -> StatementSource {
        let text = lines.joined(separator: "\n").lowercased()

        if text.contains("~|~"), text.contains("card no:") {
            return .hdfcCard
        }

        for line in lines {
            let normalized = line.lowercased()
            if normalized.contains("billingamountsign") {
                return .iciciCard
            }
            if normalized.contains("particulars"),
               normalized.contains("deposits"),
               normalized.contains("withdrawals") {
                return .iciciBank
            }
            let cols = line.components(separatedBy: ",").map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            if cols.count == 3,
               cols.contains("date"),
               cols.contains("description"),
               cols.contains("amount") {
                return .amex
            }
        }

        throw DetectionError.unrecognizedFormat("CSV format not recognized")
    }

    /// Detects institution from TXT content using narrative keywords.
    /// HDFC Bank TXT exports always contain both "narration" and "closing balance".
    private static func detectTXT(lines: [String]) throws -> StatementSource {
        let text = lines.joined(separator: "\n").lowercased()

        if text.contains("narration"), text.contains("closing balance") {
            return .hdfcBank
        }

        throw DetectionError.unrecognizedFormat("TXT format not recognized")
    }
}
