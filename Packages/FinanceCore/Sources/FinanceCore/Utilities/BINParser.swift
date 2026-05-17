import Foundation

public enum BINParser {
    public static func detectCardType(from cardNumber: String) -> String {
        let cleaned = cardNumber.filter(\.isNumber)
        guard cleaned.count >= 4 else { return "other" }

        let firstTwo = String(cleaned.prefix(2))
        let firstDigit = cleaned.first.map(String.init) ?? ""

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
        if let firstFourNum = Int(String(cleaned.prefix(4))), (2221 ... 2720).contains(firstFourNum) {
            return "mastercard"
        }

        // Discover: starts with 6011, 622126-622925, 644, 645, 646, 647, 648, 649, 65
        if firstDigit == "6" {
            if cleaned.hasPrefix("6011") {
                return "discover"
            }
            if let firstFourNum = Int(String(cleaned.prefix(4))) {
                if (644 ... 649).contains(firstFourNum) {
                    return "discover"
                }
            }
            if cleaned.hasPrefix("65") {
                return "discover"
            }
        }

        // Diners Club: starts with 300-305, 36, 38
        if firstDigit == "3" {
            if let firstThreeNum = Int(String(cleaned.prefix(3))), (300 ... 305).contains(firstThreeNum) {
                return "diners"
            }
            if firstTwo == "36" || firstTwo == "38" {
                return "diners"
            }
        }

        return "other"
    }
}
