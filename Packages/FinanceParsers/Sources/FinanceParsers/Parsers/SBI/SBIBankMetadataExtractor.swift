import Foundation

/// Extracts account metadata from SBI bank CSV rows (header block in first 10 rows).
///
/// Only account number (last 4 digits) is reliably available in the SBI CSV format;
/// all other metadata fields are returned as `nil`.
public struct SBIBankMetadataExtractor: Sendable {
    public init() {}

    /// Scans the first 10 rows for "ACCOUNT NO", "ACCOUNT NUMBER", or "A/C NO" keywords.
    public func extract(from rows: [[String]]) -> StatementMetadata {
        let accountNumber = extractAccountNumber(from: rows)
        return StatementMetadata(
            customerName: nil,
            accountNumber: accountNumber,
            fullAccountNumber: nil,
            accountType: nil,
            cardType: nil,
            generatedAt: nil
        )
    }

    private func extractAccountNumber(from rows: [[String]]) -> String? {
        for row in rows.prefix(10) {
            for cell in row {
                let trimmed = cell.trimmingCharacters(in: .whitespaces)
                let upper = trimmed.uppercased()
                if upper.contains("ACCOUNT NO") || upper.contains("ACCOUNT NUMBER") || upper.contains("A/C NO") {
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
