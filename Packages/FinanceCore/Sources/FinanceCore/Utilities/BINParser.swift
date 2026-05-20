import Foundation

/// BIN (Bank Identification Number) parser
/// Extracts card type, issuer, and validates card numbers
public enum BINParser {
    // MARK: - Public API

    /// Extracts the 6-digit BIN from a card number
    /// - Parameter cardNumber: Raw card number (can be masked or plain)
    /// - Returns: 6-digit BIN string, or empty if unavailable
    public static func extractBIN(from cardNumber: String) -> String {
        let cleaned = cardNumber.filter(\.isNumber)
        return String(cleaned.prefix(6))
    }

    /// Detects card network from card number
    /// - Parameter cardNumber: Raw card number (masked or plain)
    /// - Returns: Card network (visa, mastercard, amex, discover, diners, rupay, other)
    public static func detectCardType(from cardNumber: String) -> String {
        let cleaned = cardNumber.filter(\.isNumber)
        guard cleaned.count >= 4 else { return "other" }

        let bin = String(cleaned.prefix(6))
        let firstDigit = cleaned.first.map(String.init) ?? ""
        let firstTwo = String(bin.prefix(2))
        let firstThree = String(bin.prefix(3))
        let firstFour = String(bin.prefix(4))

        if firstDigit == "4" { return "visa" }
        if let network = detectMastercard(firstTwo: firstTwo, firstFour: firstFour) { return network }
        if firstTwo == "34" || firstTwo == "37" { return "amex" }
        if firstDigit == "3", let network = detectDiners(firstTwo: firstTwo, firstThree: firstThree) { return network }
        if firstDigit == "6" { return detectSixNetwork(bin: bin, firstFour: firstFour) }
        return "other"
    }

    private static func detectMastercard(firstTwo: String, firstFour: String) -> String? {
        if let num = Int(firstTwo), (51...55).contains(num) { return "mastercard" }
        if let num = Int(firstFour), (2221...2720).contains(num) { return "mastercard" }
        return nil
    }

    private static func detectDiners(firstTwo: String, firstThree: String) -> String? {
        if let num = Int(firstThree), (300...305).contains(num) { return "diners" }
        if firstTwo == "36" || firstTwo == "38" { return "diners" }
        return nil
    }

    private static func detectSixNetwork(bin: String, firstFour: String) -> String {
        if firstFour.hasPrefix("60") || firstFour.hasPrefix("65") { return "rupay" }
        if bin.hasPrefix("6011") || bin.hasPrefix("65") { return "discover" }
        if let num = Int(firstFour), (644...649).contains(num) { return "discover" }
        return "other"
    }

    /// Validates card number using Luhn algorithm
    /// - Parameter cardNumber: Card number to validate
    /// - Returns: True if valid, false otherwise
    public static func validateCardNumber(_ cardNumber: String) -> Bool {
        let cleaned = cardNumber.filter(\.isNumber)
        guard (13 ... 19).contains(cleaned.count) else { return false }

        var sum = 0
        var isEven = false

        for char in cleaned.reversed() {
            guard let digit = Int(String(char)) else { return false }
            var num = digit
            if isEven {
                num *= 2
                if num > 9 {
                    num -= 9
                }
            }
            sum += num
            isEven.toggle()
        }

        return sum % 10 == 0
    }

    /// Extracts last 4 digits for display
    /// - Parameter cardNumber: Card number (masked or plain)
    /// - Returns: Last 4 digits
    public static func extractLast4(from cardNumber: String) -> String {
        let cleaned = cardNumber.filter(\.isNumber)
        return String(cleaned.suffix(4))
    }
}
