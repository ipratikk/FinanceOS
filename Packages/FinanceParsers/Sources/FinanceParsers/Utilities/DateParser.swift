import Foundation

/// Stateless utility providing pre-cached `DateFormatter` instances and institution-specific
/// parse helpers. All formatters use POSIX locale and Asia/Kolkata (IST) timezone to ensure
/// deterministic parsing regardless of the user's device locale.
public enum DateParser {
    // MARK: - Cached formatters (POSIX locale + IST, safe for parsing)

    /// `dd/MM/yy` — HDFC Bank short year format.
    public static let ddMMYY: DateFormatter = makeFormatter("dd/MM/yy")
    /// `dd/MM/yyyy` — ICICI Card and HDFC Bank full year format.
    public static let ddMMYYYY: DateFormatter = makeFormatter("dd/MM/yyyy")
    /// `dd/MM/yyyy HH:mm:ss` — HDFC Card timestamp format.
    public static let ddMMYYYYHHmmss: DateFormatter = makeFormatter("dd/MM/yyyy HH:mm:ss")
    /// `dd-MM-yyyy` — ICICI Bank date format.
    public static let ddDashMMYYYY: DateFormatter = makeFormatter("dd-MM-yyyy")
    /// `dd-MMM-yyyy` — Axis/SBI abbreviated-month format.
    public static let ddDashMMMYYYY: DateFormatter = makeFormatter("dd-MMM-yyyy")
    /// `dd-MMM-yyyy HH:mm:ss` — Axis/SBI timestamp format.
    public static let ddDashMMMYYYYHHmmss: DateFormatter = makeFormatter("dd-MMM-yyyy HH:mm:ss")
    /// `MM/dd/yyyy` — American Express US date format.
    public static let mmDashDDYYYY: DateFormatter = makeFormatter("MM/dd/yyyy")

    // MARK: - Private factory

    static func makeFormatter(_ format: String) -> DateFormatter {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.timeZone = TimeZone(identifier: "Asia/Kolkata")
        fmt.dateFormat = format
        return fmt
    }

    // MARK: - Multi-format parse

    /// Attempts each format string in order, returns the first successful parse.
    public static func parse(_ string: String, formats: [String]) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        for format in formats {
            let fmt = cachedFormatter(for: format)
            if let date = fmt.date(from: trimmed) { return date }
        }
        return nil
    }

    /// Parses using a pre-cached formatter directly.
    public static func parse(_ string: String, using formatter: DateFormatter) -> Date? {
        formatter.date(from: string.trimmingCharacters(in: .whitespaces))
    }

    // MARK: - Per-institution convenience

    /// Parses ICICI Bank dates in `dd-MM-yyyy` format.
    public static func parseICICIBank(_ string: String) -> Date? {
        parse(string, using: ddDashMMYYYY)
    }

    /// Parses ICICI Card dates in `dd/MM/yyyy` format.
    public static func parseICICICard(_ string: String) -> Date? {
        parse(string, using: ddMMYYYY)
    }

    /// Parses HDFC Bank dates, trying `dd/MM/yy` then `dd/MM/yyyy`.
    public static func parseHDFCBank(_ string: String) -> Date? {
        parse(string, formats: ["dd/MM/yy", "dd/MM/yyyy"])
    }

    /// Parses HDFC Card dates in `dd/MM/yyyy HH:mm:ss` format.
    public static func parseHDFCCard(_ string: String) -> Date? {
        parse(string, using: ddMMYYYYHHmmss)
    }

    /// Parses American Express dates in `MM/dd/yyyy` format.
    public static func parseAmex(_ string: String) -> Date? {
        parse(string, using: mmDashDDYYYY)
    }

    /// Parses Axis Bank dates, trying `dd/MM/yyyy` then `dd-MMM-yyyy`.
    public static func parseAxisBank(_ string: String) -> Date? {
        parse(string, formats: ["dd/MM/yyyy", "dd-MMM-yyyy"])
    }

    /// Parses SBI dates, trying `dd/MM/yyyy` then `dd-MMM-yyyy`.
    public static func parseSBIBank(_ string: String) -> Date? {
        parse(string, formats: ["dd/MM/yyyy", "dd-MMM-yyyy"])
    }

    // MARK: - Dynamic format cache (for ad-hoc formats)

    private static var dynamicCache: [String: DateFormatter] = [:]
    private static let lock = NSLock()

    /// Returns a thread-safe cached formatter for `format`, creating it on first access.
    static func cachedFormatter(for format: String) -> DateFormatter {
        lock.lock()
        defer { lock.unlock() }
        if let existing = dynamicCache[format] { return existing }
        let fmt = makeFormatter(format)
        dynamicCache[format] = fmt
        return fmt
    }
}
