import Foundation

/// Stateless utility for converting bank statement amount strings to Int64 minor units (paise).
/// Handles INR formatting: strips `₹` symbols, thousands commas, and leading/trailing whitespace.
public enum AmountParser {
    /// Converts `string` to paise (amount × 100), preserving the sign.
    /// Returns `nil` if the string is not a valid decimal number after cleaning.
    public static func parseToInt64(_ string: String) -> Int64? {
        let cleaned = string
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let decimal = Decimal(string: cleaned) else { return nil }

        let multiplied = decimal * 100
        guard !multiplied.isNaN, multiplied.isFinite else { return nil }

        return NSDecimalNumber(decimal: multiplied).int64Value
    }

    /// Alias for `parseToInt64` — use when the caller already holds the sign externally.
    public static func parseAsSignedInt64(_ string: String) -> Int64? {
        parseToInt64(string)
    }

    /// Parses `string` and returns the absolute value in paise, ignoring any leading minus sign.
    public static func parseAsAbsoluteInt64(_ string: String) -> Int64? {
        guard let value = parseToInt64(string) else { return nil }
        return abs(value)
    }
}
