import Foundation

/// Extracts metadata from an HDFC credit card statement (tilde-pipe `~|~` delimited format).
///
/// Customer name comes from the `"Name~|~<value>"` header line.
/// Card number is read from `"Card No: XXXX XXXX XXXX 1234"` in the first 50 lines.
public struct HDFCCardMetadataExtractor: Sendable {
    public init() {}

    /// Extracts name, card last-4, full masked card number, card type, and statement date.
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
        for line in lines.prefix(20) where line.contains("Name~|~") {
            let parts = line.components(separatedBy: "~|~")
            if parts.count >= 2 {
                return parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    private func extractCardLast4(from lines: [String]) -> String? {
        for line in lines.prefix(50) where line.contains("Card No:") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let parts = trimmed.components(separatedBy: " ").filter { !$0.isEmpty }
            if let lastPart = parts.last, lastPart.count == 4, lastPart.allSatisfy(\.isNumber) {
                return lastPart
            }
        }
        return nil
    }

    private func extractFullCardNumber(from lines: [String]) -> String? {
        for line in lines.prefix(50) where line.contains("Card No:") {
            let colonParts = line.components(separatedBy: ":")
            if colonParts.count >= 2 {
                let cardNum = colonParts[1].trimmingCharacters(in: .whitespaces)
                if cardNum.count >= 12 {
                    return cardNum
                }
            }
        }
        return nil
    }

    private func extractCardType(from lines: [String]) -> String? {
        // First try to extract from keywords in statement
        let content = lines.joined(separator: " ").lowercased()
        if content.contains("visa") {
            return "visa"
        } else if content.contains("mastercard") {
            return "mastercard"
        } else if content.contains("amex") || content.contains("american express") {
            return "amex"
        }

        // Fallback: try to detect from card number using BIN
        for line in lines.prefix(50) where line.contains("Card No:") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let colonParts = trimmed.components(separatedBy: ":").last {
                let cardNum = colonParts.trimmingCharacters(in: .whitespaces)
                return detectTypeFromCardNumber(cardNum)
            }
        }

        return "other"
    }

    private func detectTypeFromCardNumber(_ cardNumber: String) -> String {
        let cleaned = cardNumber.filter(\.isNumber)
        guard cleaned.count >= 4 else { return "other" }

        let firstTwo = String(cleaned.prefix(2))
        let firstDigit = cleaned.first.map(String.init) ?? ""

        // Amex: starts with 34 or 37
        if firstTwo == "34" || firstTwo == "37" {
            return "amex"
        }

        // Visa: starts with 4
        if firstDigit == "4" {
            return "visa"
        }

        // Mastercard: starts with 51-55 or 2221-2720
        if let firstTwoNum = Int(firstTwo), (51 ... 55).contains(firstTwoNum) {
            return "mastercard"
        }
        if let firstFourNum = Int(String(cleaned.prefix(4))), (2221 ... 2720).contains(firstFourNum) {
            return "mastercard"
        }

        return "other"
    }

    private func extractStatementDate(from lines: [String]) -> Date? {
        for line in lines.prefix(20) where line.contains("Statement Date~|~") {
            let parts = line.components(separatedBy: "~|~")
            if parts.count >= 2 {
                let dateString = parts[1].trimmingCharacters(in: .whitespaces)
                return parseDate(dateString)
            }
        }
        return nil
    }

    private func parseDate(_ dateString: String) -> Date? {
        DateParser.parse(dateString, formats: ["dd/MM/yyyy", "dd/MM/yy"])
    }
}
