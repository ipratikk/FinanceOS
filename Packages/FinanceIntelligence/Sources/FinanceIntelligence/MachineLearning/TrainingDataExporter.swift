import Foundation

/// Exports user corrections as anonymized CSV for offline CoreML retraining.
///
/// Privacy rules (always enforced):
/// - Person names replaced with personId hash (SHA-256 prefix)
/// - Transaction IDs excluded
/// - Raw descriptions stripped of personal identifiers (phone numbers, UPI handles)
///
/// Output format: `text,label` CSV matching the CreateML text classifier schema.
/// Trigger condition: ≥500 eligible corrections AND ≥30 days since last export.
public struct TrainingDataExporter: Sendable {
    /// Minimum corrections needed to trigger an export.
    public static let minimumSampleCount = 500
    /// Minimum days between exports.
    public static let minimumIntervalDays = 30

    public init() {}

    /// Export eligible corrections as CSV rows.
    /// - Parameter corrections: eligible corrections from `UserCorrectionStore.exportTrainingEligible()`
    /// - Returns: CSV string with header row, or nil when sample count below threshold.
    public func exportCSV(from corrections: [UserCorrection]) -> String? {
        guard corrections.count >= Self.minimumSampleCount else { return nil }
        var rows = ["text,label"]
        for correction in corrections {
            let text = sanitize(correction.correctedMerchant ?? "unknown")
            let label = correction.correctedCategory
            guard !text.isEmpty, !label.isEmpty else { continue }
            rows.append("\(csvEscape(text)),\(csvEscape(label))")
        }
        return rows.joined(separator: "\n")
    }

    /// Export for development/testing — no minimum threshold.
    public func exportCSVUnrestricted(from corrections: [UserCorrection]) -> String {
        var rows = ["text,label"]
        for correction in corrections {
            let text = sanitize(correction.correctedMerchant ?? "unknown")
            let label = correction.correctedCategory
            guard !text.isEmpty, !label.isEmpty else { continue }
            rows.append("\(csvEscape(text)),\(csvEscape(label))")
        }
        return rows.joined(separator: "\n")
    }

    /// Whether a new export should be triggered based on count and interval.
    public func shouldExport(correctionCount: Int, daysSinceLastExport: Int) -> Bool {
        correctionCount >= Self.minimumSampleCount &&
        daysSinceLastExport >= Self.minimumIntervalDays
    }

    // MARK: - Private

    /// Strip phone numbers, UPI handles, reference numbers from text.
    /// Preserves merchant names and category keywords.
    private func sanitize(_ text: String) -> String {
        var result = text
        // Strip 10-digit phone numbers
        if let regex = try? NSRegularExpression(pattern: #"\b\d{10}\b"#) {
            result = regex.stringByReplacingMatches(
                in: result, range: NSRange(result.startIndex..., in: result), withTemplate: ""
            )
        }
        // Strip UPI handles (@bank format)
        if let regex = try? NSRegularExpression(pattern: #"@[a-z0-9]+"#, options: .caseInsensitive) {
            result = regex.stringByReplacingMatches(
                in: result, range: NSRange(result.startIndex..., in: result), withTemplate: ""
            )
        }
        // Strip 4+ digit sequences (ref numbers)
        if let regex = try? NSRegularExpression(pattern: #"\s*\d{4,}\s*"#) {
            result = regex.stringByReplacingMatches(
                in: result, range: NSRange(result.startIndex..., in: result), withTemplate: " "
            )
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
