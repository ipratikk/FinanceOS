import Foundation

public struct HDFCBankMetadataExtractor: Sendable {
    public init() {}

    public func extract(from content: String) -> StatementMetadata {
        let lines = content.components(separatedBy: .newlines)

        let customerName = extractCustomerName(from: lines)
        let accountLast4 = extractAccountLast4(from: lines)
        let fullAccountNumber = extractFullAccountNumber(from: lines)
        let accountType = extractAccountType(from: lines)
        let statementDate = extractStatementDate(from: lines)

        return StatementMetadata(
            customerName: customerName,
            accountNumber: accountLast4,
            fullAccountNumber: fullAccountNumber,
            accountType: accountType,
            cardType: nil,
            generatedAt: statementDate
        )
    }

    private func extractCustomerName(from lines: [String]) -> String? {
        for line in lines.prefix(20) {
            if line.contains("Customer Name") || line.contains("NAME~|~") {
                let parts = line.components(separatedBy: "~|~")
                if parts.count >= 2 {
                    return parts[1].trimmingCharacters(in: .whitespaces)
                } else if line.contains("Customer Name") {
                    let colonParts = line.components(separatedBy: ":")
                    if colonParts.count >= 2 {
                        return colonParts[1].trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        return nil
    }

    private func extractAccountLast4(from lines: [String]) -> String? {
        for line in lines.prefix(25) {
            if line.contains("Account"), line.contains("XXXXXXXX") {
                let pattern = "XXXXXXXX(\\d{4})"
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(line.startIndex..., in: line)
                    if let match = regex.firstMatch(in: line, range: range) {
                        if let matchRange = Range(match.range(at: 1), in: line) {
                            return String(line[matchRange])
                        }
                    }
                }
            }
        }
        return nil
    }

    private func extractFullAccountNumber(from lines: [String]) -> String? {
        for line in lines.prefix(25) {
            if line.contains("Account") && line.contains("XXXXXXXX") {
                let pattern = "([0-9X]+)"
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(line.startIndex..., in: line)
                    if let match = regex.firstMatch(in: line, range: range) {
                        if let matchRange = Range(match.range(at: 1), in: line) {
                            let accountNum = String(line[matchRange])
                            if accountNum.contains("X") || accountNum.count >= 12 {
                                return accountNum
                            }
                        }
                    }
                }
            }
        }
        return nil
    }

    private func extractAccountType(from lines: [String]) -> String? {
        for line in lines.prefix(25) {
            let lower = line.lowercased()
            if lower.contains("account type") || lower.contains("type~|~") {
                let parts = line.components(separatedBy: "~|~")
                if parts.count >= 2 {
                    return parts[1].trimmingCharacters(in: .whitespaces)
                } else {
                    let colonParts = line.components(separatedBy: ":")
                    if colonParts.count >= 2 {
                        return colonParts[1].trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        return nil
    }

    private func extractStatementDate(from lines: [String]) -> Date? {
        for line in lines.prefix(20) {
            if line.contains("Statement Date") || line.contains("Statement Period") {
                let colonParts = line.components(separatedBy: ":")
                if colonParts.count >= 2 {
                    let dateString = colonParts[1].trimmingCharacters(in: .whitespaces)
                    return parseDate(dateString)
                }
            }
        }
        return nil
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formats = ["dd/MM/yyyy", "dd/MM/yy", "dd-MMM-yyyy"]
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
