import Foundation

public struct HDFCCardMetadataExtractor: Sendable {
    public init() {}

    public func extract(from content: String) -> StatementMetadata {
        let lines = content.components(separatedBy: .newlines)

        let customerName = extractCustomerName(from: lines)
        let cardLast4 = extractCardLast4(from: lines)
        let fullCardNumber = extractFullCardNumber(from: lines)
        let cardType = extractCardType(from: lines)
        let statementDate = extractStatementDate(from: lines)

        return StatementMetadata(
            customerName: customerName,
            accountNumber: cardLast4,
            fullAccountNumber: fullCardNumber,
            accountType: nil,
            cardType: cardType,
            generatedAt: statementDate
        )
    }

    private func extractCustomerName(from lines: [String]) -> String? {
        for line in lines.prefix(20) {
            if line.contains("Name~|~") {
                let parts = line.components(separatedBy: "~|~")
                if parts.count >= 2 {
                    return parts[1].trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return nil
    }

    private func extractCardLast4(from lines: [String]) -> String? {
        for line in lines.prefix(50) {
            if line.contains("Card No:") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let parts = trimmed.components(separatedBy: " ").filter { !$0.isEmpty }
                if let lastPart = parts.last, lastPart.count == 4, lastPart.allSatisfy(\.isNumber) {
                    return lastPart
                }
            }
        }
        return nil
    }

    private func extractFullCardNumber(from lines: [String]) -> String? {
        for line in lines.prefix(50) {
            if line.contains("Card No:") {
                let colonParts = line.components(separatedBy: ":")
                if colonParts.count >= 2 {
                    let cardNum = colonParts[1].trimmingCharacters(in: .whitespaces)
                    if cardNum.count >= 12 {
                        return cardNum
                    }
                }
            }
        }
        return nil
    }

    private func extractCardType(from lines: [String]) -> String? {
        let content = lines.joined(separator: " ").lowercased()
        if content.contains("visa") {
            return "visa"
        } else if content.contains("mastercard") {
            return "mastercard"
        } else if content.contains("amex") {
            return "amex"
        }
        return "other"
    }

    private func extractStatementDate(from lines: [String]) -> Date? {
        for line in lines.prefix(20) {
            if line.contains("Statement Date~|~") {
                let parts = line.components(separatedBy: "~|~")
                if parts.count >= 2 {
                    let dateString = parts[1].trimmingCharacters(in: .whitespaces)
                    return parseDate(dateString)
                }
            }
        }
        return nil
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formats = ["dd/MM/yyyy", "dd/MM/yy"]
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
