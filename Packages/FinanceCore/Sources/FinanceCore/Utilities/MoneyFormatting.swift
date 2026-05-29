import Foundation

/// Centralized minor-unit → display string conversion.
/// Eliminates repeated minorUnits / 100 arithmetic and fresh NumberFormatter allocations.
public enum MoneyFormatting {
    // MARK: - Cached formatters

    private static let inrGrouped: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.locale = Locale(identifier: "en_IN")
        fmt.minimumFractionDigits = 0
        fmt.maximumFractionDigits = 0
        return fmt
    }()

    private static let standardGrouped: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.groupingSeparator = ","
        fmt.groupingSize = 3
        fmt.minimumFractionDigits = 0
        fmt.maximumFractionDigits = 0
        return fmt
    }()

    private static let standardGroupedTwo: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.groupingSeparator = ","
        fmt.groupingSize = 3
        fmt.minimumFractionDigits = 2
        fmt.maximumFractionDigits = 2
        return fmt
    }()

    // MARK: - Transaction amount display

    /// Returns "-₹1234.56" or "+₹1234.56" (no thousand separator, exact minor-unit math).
    /// Replaces the repeated `amountText(minorUnits:currencyCode:transactionType:)` pattern.
    public static func format(
        minorUnits: Int64,
        currencyCode: String,
        transactionType: TransactionType
    ) -> String {
        let whole = abs(minorUnits) / 100
        let frac = abs(minorUnits) % 100
        let symbol = CurrencySymbol.symbol(for: currencyCode)
        let sign = transactionType == .debit ? "-" : "+"
        return "\(sign)\(symbol)\(whole).\(String(format: "%02d", frac))"
    }

    // MARK: - Balance display

    /// Returns "₹1,23,456" or "-₹1,23,456.78" (Indian grouping, optional paise).
    /// Replaces AccountsViewModel.AccountLedgerBalance.formattedBalance.
    public static func formatBalance(minorUnits: Int64, currencyCode: String = "INR") -> String {
        let sign = minorUnits < 0 ? "-" : ""
        let absValue = abs(minorUnits)
        let whole = absValue / 100
        let frac = absValue % 100
        let symbol = CurrencySymbol.symbol(for: currencyCode)
        let formatted = inrGrouped.string(from: NSNumber(value: whole)) ?? "\(whole)"
        return frac > 0
            ? "\(sign)\(symbol)\(formatted).\(String(format: "%02d", frac))"
            : "\(sign)\(symbol)\(formatted)"
    }

    /// Returns "₹1,234.56" (US-style grouping, always shows paise).
    /// Replaces AccountTransactionsViewModel.balanceText for running-balance column.
    public static func formatRunningBalance(minorUnits: Int64, currencyCode: String = "INR") -> String {
        let whole = minorUnits / 100
        let frac = abs(minorUnits % 100)
        let symbol = CurrencySymbol.symbol(for: currencyCode)
        let formatted = standardGrouped.string(from: NSNumber(value: whole)) ?? "\(whole)"
        return "\(symbol)\(formatted).\(String(format: "%02d", frac))"
    }

    // MARK: - Analytics display

    /// Returns "₹1,234" (rounded to whole units, comma-grouped).
    /// Replaces AnalyticsFormatting.rupees(_:).
    public static func formatRounded(minorUnits: Int64, currencyCode: String = "INR") -> String {
        let value = Double(minorUnits) / 100.0
        let symbol = CurrencySymbol.symbol(for: currencyCode)
        let formatted = standardGrouped.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(symbol)\(formatted)"
    }

    /// Returns "+₹1,234.56" or "₹1,234.56" (comma-grouped, two decimal places).
    /// Replaces AnalyticsFormatting.rupeesWithSign(_:isDebit:).
    public static func formatWithSign(
        minorUnits: Int64,
        isDebit: Bool,
        currencyCode: String = "INR"
    ) -> String {
        let value = Double(minorUnits) / 100.0
        let symbol = CurrencySymbol.symbol(for: currencyCode)
        let formatted = standardGroupedTwo.string(from: NSNumber(value: value))
            ?? String(format: "%.2f", value)
        let sign = isDebit ? "" : "+"
        return "\(sign)\(symbol)\(formatted)"
    }
}

// MARK: - Int64 convenience extensions

public extension Int64 {
    /// Formats a minor-unit amount with sign and currency symbol for transaction row display.
    func formattedAsAmount(currencyCode: String, transactionType: TransactionType) -> String {
        MoneyFormatting.format(minorUnits: self, currencyCode: currencyCode, transactionType: transactionType)
    }

    /// Formats a minor-unit balance with Indian grouping (lakhs/crores) for account balance display.
    func formattedAsBalance(currencyCode: String = "INR") -> String {
        MoneyFormatting.formatBalance(minorUnits: self, currencyCode: currencyCode)
    }

    /// Formats a minor-unit amount rounded to whole units for analytics chart labels.
    func formattedAsRounded(currencyCode: String = "INR") -> String {
        MoneyFormatting.formatRounded(minorUnits: self, currencyCode: currencyCode)
    }
}
