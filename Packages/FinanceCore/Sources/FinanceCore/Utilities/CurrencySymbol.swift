import Foundation

public enum CurrencySymbol {
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
