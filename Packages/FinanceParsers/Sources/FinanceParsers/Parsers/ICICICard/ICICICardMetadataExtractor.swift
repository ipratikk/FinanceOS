import Foundation

public struct ICICICardMetadataExtractor: Sendable {
    public init() {}

    public func extract(from rows: [[String]]) -> StatementMetadata {
        let customerName = extractCustomerName(from: rows)
        let cardLast4 = extractCardLast4(from: rows)
        let statementDate = extractStatementDate(from: rows)

        return StatementMetadata(
            customerName: customerName,
            accountNumber: cardLast4,
            fullAccountNumber: nil,
            accountType: nil,
            cardType: nil,
            generatedAt: statementDate
        )
    }

    private func extractCustomerName(from rows: [[String]]) -> String? {
        for row in rows.prefix(15) {
            guard let firstCol = row.first else { continue }
            let trimmed = firstCol.trimmingCharacters(in: .whitespaces)
            if trimmed.uppercased().contains("CARDHOLDER NAME") {
                if row.count > 1 {
                    return row[1].trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return nil
    }

    private func extractCardLast4(from rows: [[String]]) -> String? {
        for row in rows.prefix(15) {
            guard let firstCol = row.first else { continue }
            let trimmed = firstCol.trimmingCharacters(in: .whitespaces)
            if trimmed.uppercased().contains("CARD NUMBER") {
                if row.count > 1 {
                    let cardNum = row[1].trimmingCharacters(in: .whitespaces)
                    let parts = cardNum
                        .trimmingCharacters(in: .whitespaces)
                        .components(separatedBy: " ")
                        .filter { !$0.isEmpty }
                    if let lastPart = parts.last, lastPart.count == 4, lastPart.allSatisfy(\.isNumber) {
                        return lastPart
                    }
                }
            }
        }
        return nil
    }

    private func extractStatementDate(from rows: [[String]]) -> Date? {
        for row in rows.prefix(15) {
            guard let firstCol = row.first else { continue }
            let trimmed = firstCol.trimmingCharacters(in: .whitespaces)
            if trimmed.uppercased().contains("STATEMENT DATE") || trimmed.uppercased().contains("AS ON") {
                if row.count > 1 {
                    let dateString = row[1].trimmingCharacters(in: .whitespaces)
                    return parseDate(dateString)
                }
            }
        }
        return nil
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formats = ["dd/MM/yyyy", "dd-MMM-yyyy", "MMM dd, yyyy"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }
}
