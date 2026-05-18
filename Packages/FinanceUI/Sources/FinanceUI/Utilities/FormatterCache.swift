import Foundation

/// Centralized formatter caching to eliminate repeated NumberFormatter/DateFormatter allocation.
/// Formatters are expensive; cache them as static singletons.
public struct FormatterCache {
    // MARK: - Currency Formatter (INR)

    public static let currencyINR: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = "INR"
        fmt.minimumFractionDigits = 0
        fmt.maximumFractionDigits = 2
        return fmt
    }()

    public static let currencyUSD: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = "USD"
        fmt.minimumFractionDigits = 0
        fmt.maximumFractionDigits = 2
        return fmt
    }()

    public static let currencyEUR: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = "EUR"
        fmt.minimumFractionDigits = 0
        fmt.maximumFractionDigits = 2
        return fmt
    }()

    // MARK: - Decimal Formatter (No Currency)

    public static let decimal: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.minimumFractionDigits = 0
        fmt.maximumFractionDigits = 2
        return fmt
    }()

    // MARK: - Date Formatters

    public static let datemediumLong: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt
    }()

    public static let dateShort: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .none
        return fmt
    }()

    public static let dateAndTime: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt
    }()

    public static let monthYear: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt
    }()

    // MARK: - ISO8601 Formatter

    public static let iso8601: ISO8601DateFormatter = {
        ISO8601DateFormatter()
    }()

    // MARK: - Utility Methods

    /// Format currency amount with specified code.
    public static func formatCurrency(_ amount: Decimal, currencyCode: String = "INR") -> String {
        let formatter: NumberFormatter
        switch currencyCode {
        case "USD": formatter = currencyUSD
        case "EUR": formatter = currencyEUR
        default: formatter = currencyINR
        }
        return formatter.string(from: amount as NSNumber) ?? "N/A"
    }

    /// Format date using locale-aware short format.
    public static func formatDate(_ date: Date) -> String {
        dateShort.string(from: date)
    }

    /// Format date and time using locale-aware format.
    public static func formatDateTime(_ date: Date) -> String {
        dateAndTime.string(from: date)
    }

    /// Format month and year (e.g., "May 2026").
    public static func formatMonthYear(_ date: Date) -> String {
        monthYear.string(from: date)
    }
}
