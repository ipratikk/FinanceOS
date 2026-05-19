import Foundation

public enum BINParser {
    public static func detectCardType(from cardNumber: String) -> String {
        // Extract first 6 digits, handling masked formats (5522 60XX XXXX 7880)
        let cleaned = cardNumber.filter(\.isNumber)
        guard cleaned.count >= 4 else { return "other" }

        // Try to get first 6 digits; if less available, use what we have
        let binDigits: String = if cleaned.count >= 6 {
            String(cleaned.prefix(6))
        } else {
            cleaned
        }

        let firstTwo = String(binDigits.prefix(2))
        let firstDigit = binDigits.first.map(String.init) ?? ""
        let firstFour = String(binDigits.prefix(4))

        // Amex: starts with 34 or 37
        if firstTwo == "34" || firstTwo == "37" {
            return "amex"
        }

        // Visa: starts with 4
        if firstDigit == "4" {
            return "visa"
        }

        // Mastercard: starts with 51-55 or 2221-2720
        if let firstTwoNum = Int(firstTwo), (51 ... 55).contains(firstTwoNum) {
            return "mastercard"
        }
        if let firstFourNum = Int(firstFour), (2221 ... 2720).contains(firstFourNum) {
            return "mastercard"
        }

        // Discover: starts with 6011, 622126-622925, 644, 645, 646, 647, 648, 649, 65
        if firstDigit == "6" {
            if binDigits.hasPrefix("6011") {
                return "discover"
            }
            if let firstFourNum = Int(firstFour) {
                if (644 ... 649).contains(firstFourNum) {
                    return "discover"
                }
            }
            if binDigits.hasPrefix("65") {
                return "discover"
            }
        }

        // Diners Club: starts with 300-305, 36, 38
        if firstDigit == "3" {
            if let firstThreeNum = Int(String(binDigits.prefix(3))), (300 ... 305).contains(firstThreeNum) {
                return "diners"
            }
            if firstTwo == "36" || firstTwo == "38" {
                return "diners"
            }
        }

        return "other"
    }
}
