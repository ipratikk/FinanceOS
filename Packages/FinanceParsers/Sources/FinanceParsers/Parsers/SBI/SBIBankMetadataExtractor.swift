import Foundation

public struct SBIBankMetadataExtractor: Sendable {
    public init() {}

    public func extract(from rows: [[String]]) -> StatementMetadata {
        let accountNumber = extractAccountNumber(from: rows)
        return StatementMetadata(
            customerName: nil,
            accountNumber: accountNumber,
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
