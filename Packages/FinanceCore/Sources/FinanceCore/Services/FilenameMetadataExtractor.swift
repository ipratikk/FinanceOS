import Foundation

public struct FilenameMetadataExtractor {
    public init() {}

    public func extractMetadata(from filename: String) -> FilenameMetadata {
        let basename = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent

        return FilenameMetadata(
            accountLast4: extractAccountLast4(from: basename),
            accountNumber: extractAccountNumber(from: basename),
            statementDate: extractStatementDate(from: basename),
            bankHint: extractBankHint(from: basename)
        )
    }

    private func extractAccountLast4(from filename: String) -> String? {
        // Look for patterns like "1234", "****1234", "xxxx1234" at word boundaries
        let patterns = [
            "(?:x{4}|\\*{4})(\\d{4})", // ****1234 or xxxx1234
            "\\b(\\d{4})\\b" // standalone 4-digit sequence
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(filename.startIndex..., in: filename)
                if let match = regex.firstMatch(in: filename, range: range) {
                    if let matchRange = Range(match.range(at: 1), in: filename) {
                        let last4 = String(filename[matchRange])
                        if last4.count == 4, last4.allSatisfy(\.isNumber) {
                            return last4
                        }
                    }
                }
            }
        }
        return nil
    }

    private func extractAccountNumber(from filename: String) -> String? {
        // Look for longer digit sequences that could be account numbers
        let pattern = "(\\d{10,16})"

        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(filename.startIndex..., in: filename)
            if let match = regex.firstMatch(in: filename, range: range) {
                if let matchRange = Range(match.range(at: 1), in: filename) {
                    return String(filename[matchRange])
                }
            }
        }
        return nil
    }

    private func extractStatementDate(from filename: String) -> Date? {
        // Look for date patterns: YYYY-MM-DD, DD-MM-YYYY, MMDDYYYY, etc
        let datePatterns = [
            ("yyyy-MM-dd", "\\d{4}-\\d{2}-\\d{2}"),
            ("dd-MM-yyyy", "\\d{2}-\\d{2}-\\d{4}"),
            ("ddMMyyyy", "\\d{8}"),
            ("yyyyMMdd", "\\d{8}"),
            ("MMM yyyy", "[A-Za-z]{3}\\s\\d{4}"),
            ("MMMM yyyy", "[A-Za-z]+\\s\\d{4}")
        ]

        for (format, pattern) in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(filename.startIndex..., in: filename)
                if let match = regex.firstMatch(in: filename, range: range) {
                    if let matchRange = Range(match.range, in: filename) {
                        let dateString = String(filename[matchRange])
                        if let date = parseDate(dateString, format: format) {
                            return date
                        }
                    }
                }
            }
        }
        return nil
    }

    private func extractBankHint(from filename: String) -> String? {
        let bankNames = ["HDFC", "ICICI", "Axis", "SBI", "Amex", "AMEX", "Bank", "Visa", "MasterCard", "Diners"]

        let lower = filename.lowercased()
        for bankName in bankNames {
            if lower.contains(bankName.lowercased()) {
                return bankName
            }
        }
        return nil
    }

    private func parseDate(_ dateString: String, format: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: dateString)
    }
}

public struct FilenameMetadata: Sendable {
    public let accountLast4: String?
    public let accountNumber: String?
    public let statementDate: Date?
    public let bankHint: String?

    public init(
        accountLast4: String? = nil,
        accountNumber: String? = nil,
        statementDate: Date? = nil,
        bankHint: String? = nil
    ) {
        self.accountLast4 = accountLast4
        self.accountNumber = accountNumber
        self.statementDate = statementDate
        self.bankHint = bankHint
    }
}
