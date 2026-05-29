import Foundation

/// Extracts card metadata from Axis card CSV rows (header block in first 10 rows).
///
/// Only card last-4 digits are reliably available; all other fields return `nil`.
public struct AxisCardMetadataExtractor: Sendable {
    public init() {}

    /// Scans the first 10 rows for "CARD NO" or "CARD NUMBER" keywords to extract last-4 digits.
    public func extract(from rows: [[String]]) -> StatementMetadata {
        let cardLast4 = extractCardLast4(from: rows)
        return StatementMetadata(
            customerName: nil,
            accountNumber: cardLast4,
            fullAccountNumber: nil,
            accountType: nil,
            cardType: nil,
            generatedAt: nil
        )
    }

    private func extractCardLast4(from rows: [[String]]) -> String? {
        for row in rows.prefix(10) {
            for cell in row {
                let trimmed = cell.trimmingCharacters(in: .whitespaces)
                let upper = trimmed.uppercased()
                if upper.contains("CARD NO") || upper.contains("CARD NUMBER") {
                    let digits = trimmed.filter(\.isNumber)
                    if digits.count >= 4 {
                        return String(digits.suffix(4))
                    }
                }
            }
        }
        return nil
    }
}
