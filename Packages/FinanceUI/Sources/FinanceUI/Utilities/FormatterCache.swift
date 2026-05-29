import Foundation

/// Centralized formatter caching to eliminate repeated NumberFormatter/DateFormatter allocation.
/// Formatters are expensive; cache them as static singletons.
public enum FormatterCache {
    // MARK: - Currency Formatter (INR)

    /// Shared INR currency formatter. 0–2 fraction digits, currency symbol included.
    public static let currencyINR: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = "INR"
        fmt.minimumFractionDigits = 0
        fmt.maximumFractionDigits = 2
        return fmt
    }()

    /// Shared USD currency formatter.
    public static let currencyUSD: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = "USD"
        fmt.minimumFractionDigits = 0
        fmt.maximumFractionDigits = 2
        return fmt
    }()

    /// Shared EUR currency formatter.
    public static let currencyEUR: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = "EUR"
        fmt.minimumFractionDigits = 0
        fmt.maximumFractionDigits = 2
        return fmt
    }()

    // MARK: - Decimal Formatter (No Currency)

    /// Shared decimal formatter — no currency symbol, 0–2 fraction digits.
    public static let decimal: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.minimumFractionDigits = 0
        fmt.maximumFractionDigits = 2
        return fmt
    }()

    // MARK: - Date Formatters

    /// Date only, medium style (e.g. "May 29, 2026").
    public static let datemediumLong: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt
    }()

    /// Date only, short style (e.g. "5/29/26").
    public static let dateShort: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .none
        return fmt
    }()

    /// Date with time (e.g. "May 29, 2026 at 3:45 PM").
    public static let dateAndTime: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt
    }()

    /// Month and year only (e.g. "May 2026").
    public static let monthYear: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt
    }()

    /// Day, abbreviated month, and 12h time (e.g. "May 29 · 3:45 PM").
    public static let dayAndTime: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d · h:mm a"
        return fmt
    }()

    /// Full weekday and date (e.g. "Thursday, May 29").
    public static let fullDayDate: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        return fmt
    }()

    /// Compact day and abbreviated month (e.g. "29 May").
    public static let shortDayMonth: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        return fmt
    }()

    /// Day, abbreviated month, and year (e.g. "29 May 2026").
    public static let dayMonthYear: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM yyyy"
        return fmt
    }()

    /// Slash-separated date matching HDFC/ICICI CSV format (e.g. "29/05/2026").
    public static let slashDate: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "dd/MM/yyyy"
        return fmt
    }()

    /// Abbreviated month name only (e.g. "May").
    public static let shortMonth: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        return fmt
    }()

    /// Day, month, comma, year (e.g. "29 May, 2026").
    public static let dayMonthCommaYear: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM, yyyy"
        return fmt
    }()

    // MARK: - ISO8601 Formatter

    /// Shared ISO 8601 formatter for machine-readable date round-trips.
    public static let iso8601: ISO8601DateFormatter = ISO8601DateFormatter()

    // MARK: - Utility Methods

    /// Format currency amount with specified code.
    public static func formatCurrency(_ amount: Decimal, currencyCode: String = "INR") -> String {
        let formatter: NumberFormatter = switch currencyCode {
        case "USD": currencyUSD
        case "EUR": currencyEUR
        default: currencyINR
        }
        return formatter.string(from: amount as NSNumber) ?? "N/A"
    }

    /// Format minor units (Int64) as currency string.
    public static func formatCurrency(minorUnits: Int64, currencyCode: String = "INR") -> String {
        let amount = Decimal(minorUnits) / 100
        return formatCurrency(amount, currencyCode: currencyCode)
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
