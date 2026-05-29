import Foundation

/// Maps ISO 4217 currency codes to their display symbols.
/// Falls back to the raw code string for currencies not explicitly listed.
public enum CurrencySymbol {
    /// Returns the display symbol for `code` (e.g. "INR" → "₹", "USD" → "$").
    public static func symbol(for code: String) -> String {
        switch code.uppercased() {
        case "INR": return "₹"
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "AUD": return "A$"
        case "CAD": return "C$"
        case "SGD": return "S$"
        default: return code
        }
    }
}
