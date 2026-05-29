import Foundation

public struct ICICICardMetadataExtractor: Sendable {
    public init() {}

    public func extract(from rows: [[String]]) -> StatementMetadata {
        let customerName = extractCustomerName(from: rows)
        let cardLast4 = extractCardLast4(from: rows)
        let maskedCardNumber = extractMaskedCardNumber(from: rows)
        let statementDate = extractStatementDate(from: rows)

        return StatementMetadata(
            customerName: customerName,
            accountNumber: cardLast4,
            fullAccountNumber: maskedCardNumber,
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
        guard let maskedCard = extractMaskedCardNumber(from: rows) else {
            return extractLabeledCardNumber(from: rows)
        }
        let last4 = String(maskedCard.suffix(4))
        return last4.allSatisfy(\.isNumber) ? last4 : nil
    }

    private func extractMaskedCardNumber(from rows: [[String]]) -> String? {
        for row in rows.prefix(15) {
            guard let firstCol = row.first else { continue }
            let trimmed = firstCol.trimmingCharacters(in: .whitespaces)

            if row.count == 1 {
                let cardPattern = trimmed.uppercased()
                if cardPattern.contains("X"), trimmed.count >= 13 {
                    let last4 = String(trimmed.suffix(4))
                    if last4.allSatisfy(\.isNumber) {
                        return trimmed
                    }
                }
            }
        }
        return nil
    }

    private func extractLabeledCardNumber(from rows: [[String]]) -> String? {
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
        DateParser.parse(dateString, formats: ["dd/MM/yyyy", "dd-MMM-yyyy", "MMM dd, yyyy"])
    }
}
