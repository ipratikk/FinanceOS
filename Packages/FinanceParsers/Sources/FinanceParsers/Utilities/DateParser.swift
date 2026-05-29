import Foundation

public enum DateParser {
    // MARK: - Cached formatters (POSIX locale + IST, safe for parsing)

    public static let ddMMYY: DateFormatter = makeFormatter("dd/MM/yy")
    public static let ddMMYYYY: DateFormatter = makeFormatter("dd/MM/yyyy")
    public static let ddMMYYYYHHmmss: DateFormatter = makeFormatter("dd/MM/yyyy HH:mm:ss")
    public static let ddDashMMYYYY: DateFormatter = makeFormatter("dd-MM-yyyy")
    public static let ddDashMMMYYYY: DateFormatter = makeFormatter("dd-MMM-yyyy")
    public static let ddDashMMMYYYYHHmmss: DateFormatter = makeFormatter("dd-MMM-yyyy HH:mm:ss")
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

    public static func parseICICIBank(_ string: String) -> Date? {
        parse(string, using: ddDashMMYYYY)
    }

    public static func parseICICICard(_ string: String) -> Date? {
        parse(string, using: ddMMYYYY)
    }

    public static func parseHDFCBank(_ string: String) -> Date? {
        parse(string, formats: ["dd/MM/yy", "dd/MM/yyyy"])
    }

    public static func parseHDFCCard(_ string: String) -> Date? {
        parse(string, using: ddMMYYYYHHmmss)
    }

    public static func parseAmex(_ string: String) -> Date? {
        parse(string, using: mmDashDDYYYY)
    }

    public static func parseAxisBank(_ string: String) -> Date? {
        parse(string, formats: ["dd/MM/yyyy", "dd-MMM-yyyy"])
    }

    public static func parseSBIBank(_ string: String) -> Date? {
        parse(string, formats: ["dd/MM/yyyy", "dd-MMM-yyyy"])
    }

    // MARK: - Dynamic format cache (for ad-hoc formats)

    private static var dynamicCache: [String: DateFormatter] = [:]
    private static let lock = NSLock()

    static func cachedFormatter(for format: String) -> DateFormatter {
        lock.lock()
        defer { lock.unlock() }
        if let existing = dynamicCache[format] { return existing }
        let fmt = makeFormatter(format)
        dynamicCache[format] = fmt
        return fmt
    }
}
