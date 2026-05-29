import Foundation
import OSLog

/// Extracts account metadata (last-4, account number, date, bank hint) from a statement filename.
/// Used during import to pre-populate the account-matching form without parsing the file body.
public struct FilenameMetadataExtractor {
    private let logger = FinanceLogger.parsing

    public init() {}

    /// Runs all extraction patterns against `filename` and returns whatever metadata could be inferred.
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
        let patterns = [
            "(?:x{4}|\\*{4})(\\d{4})",
            "\\b(\\d{4})\\b"
        ]

        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(filename.startIndex..., in: filename)
                if let match = regex.firstMatch(in: filename, range: range) {
                    if let matchRange = Range(match.range(at: 1), in: filename) {
                        let last4 = String(filename[matchRange])
                        if last4.count == 4, last4.allSatisfy(\.isNumber) {
                            return last4
                        }
                    }
                }
            } catch {
                logger.logDebug(
                    "Regex pattern failed for last4: {pattern}",
                    ["pattern": pattern]
                )
            }
        }
        return nil
    }

    private func extractAccountNumber(from filename: String) -> String? {
        let pattern = "(\\d{10,16})"

        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(filename.startIndex..., in: filename)
            if let match = regex.firstMatch(in: filename, range: range) {
                if let matchRange = Range(match.range(at: 1), in: filename) {
                    return String(filename[matchRange])
                }
            }
        } catch {
            logger.logDebug(
                "Failed to extract account number",
                ["error": String(describing: error)]
            )
        }
        return nil
    }

    private func extractStatementDate(from filename: String) -> Date? {
        let datePatterns = [
            ("yyyy-MM-dd", "\\d{4}-\\d{2}-\\d{2}"),
            ("dd-MM-yyyy", "\\d{2}-\\d{2}-\\d{4}"),
            ("ddMMyyyy", "\\d{8}"),
            ("yyyyMMdd", "\\d{8}"),
            ("MMM yyyy", "[A-Za-z]{3}\\s\\d{4}"),
            ("MMMM yyyy", "[A-Za-z]+\\s\\d{4}")
        ]

        for (format, pattern) in datePatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let range = NSRange(filename.startIndex..., in: filename)
                if let match = regex.firstMatch(in: filename, range: range) {
                    if let matchRange = Range(match.range, in: filename) {
                        let dateString = String(filename[matchRange])
                        if let date = parseDate(dateString, format: format) {
                            return date
                        }
                    }
                }
            } catch {
                logger.logDebug(
                    "Regex pattern failed for date {format}",
                    ["format": format]
                )
            }
        }
        return nil
    }

    private func extractBankHint(from filename: String) -> String? {
        let bankNames = ["HDFC", "ICICI", "Axis", "SBI", "Amex", "AMEX", "Bank", "Visa", "MasterCard", "Diners"]

        let lower = filename.lowercased()
        for bankName in bankNames where lower.contains(bankName.lowercased()) {
            return bankName
        }
        return nil
    }

    private nonisolated(unsafe) static var dateFormatterCache: [String: DateFormatter] = [:]
    private static let cachelock = NSLock()

    private func parseDate(_ dateString: String, format: String) -> Date? {
        Self.cachelock.lock()
        defer { Self.cachelock.unlock() }
        let formatter: DateFormatter
        if let cached = Self.dateFormatterCache[format] {
            formatter = cached
        } else {
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.dateFormat = format
            Self.dateFormatterCache[format] = fmt
            formatter = fmt
        }
        return formatter.date(from: dateString)
    }
}

/// Structured metadata inferred from a statement filename; all fields are optional and best-effort.
public struct FilenameMetadata: Sendable {
    public let accountLast4: String?
    public let accountNumber: String?
    public let statementDate: Date?
    /// Partial bank name token found in the filename (e.g. "HDFC", "ICICI"); not a validated bank identifier.
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
