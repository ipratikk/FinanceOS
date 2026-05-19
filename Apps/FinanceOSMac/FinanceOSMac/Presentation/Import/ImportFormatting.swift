import FinanceParsers
import Foundation

enum ImportFormatting {
    static func formatAmount(_ minorUnits: Int64) -> String {
        let amount = Double(minorUnits) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        return formatter.string(from: NSNumber(value: amount)) ?? "₹\(amount)"
    }

    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    static func fuzzyMatch(_ stored: String, _ parsed: String) -> Bool {
        let storedLower = stored.lowercased()
        let parsedLower = parsed.lowercased()

        if storedLower == parsedLower { return true }
        if storedLower.contains(parsedLower) || parsedLower.contains(storedLower) {
            return true
        }

        let storedWords = storedLower.split(separator: " ").map(String.init)
        let parsedWords = parsedLower.split(separator: " ").map(String.init)

        let commonWords = Set(storedWords).intersection(Set(parsedWords))
        return !commonWords.isEmpty &&
            commonWords.count >= min(storedWords.count, parsedWords.count) / 2
    }
}
