import Foundation

/// Exports user corrections from `UserCorrectionStore` to a CSV file
/// suitable for incremental model retraining.
///
/// Format: `text,label\n` (matches Python training pipeline format).
public struct FeedbackExporter: Sendable {
    public static let minimumExportCount = 50
    public static let exportIntervalDays = 7

    public init() {}

    /// Export corrections to a CSV string. Returns nil when below minimum count.
    public func exportCSV(from corrections: [UserCorrection]) -> String? {
        let eligible = corrections.filter { $0.isTrainingEligible }
        guard eligible.count >= Self.minimumExportCount else { return nil }
        return buildCSV(from: eligible)
    }

    /// Export without minimum count check — for testing or forced export.
    public func exportCSVUnrestricted(from corrections: [UserCorrection]) -> String {
        buildCSV(from: corrections)
    }

    /// Whether enough time and corrections have accumulated to warrant a new export.
    public func shouldExport(correctionCount: Int, daysSinceLastExport: Int) -> Bool {
        correctionCount >= Self.minimumExportCount && daysSinceLastExport >= Self.exportIntervalDays
    }

    /// Write CSV to a file URL. Returns the file path on success.
    public func writeCSV(from corrections: [UserCorrection], to url: URL) throws -> URL {
        let csv = buildCSV(from: corrections)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Private

    private func buildCSV(from corrections: [UserCorrection]) -> String {
        var lines = ["text,label"]
        for correction in corrections {
            guard let text = correction.correctedMerchant ?? correction.originalMerchant else { continue }
            let label = correction.correctedCategory
            let sanitized = sanitize(text)
            let escapedText = sanitized.contains(",") ? "\"\(sanitized)\"" : sanitized
            lines.append("\(escapedText),\(label)")
        }
        return lines.joined(separator: "\n")
    }

    private func sanitize(_ text: String) -> String {
        var result = text.lowercased()
        // Remove phone numbers
        result = result.replacingOccurrences(of: "\\b\\d{10}\\b", with: "", options: .regularExpression)
        // Remove UPI handles
        result = result.replacingOccurrences(of: "@\\w+", with: "", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespaces)
    }
}
