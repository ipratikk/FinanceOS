import Foundation

enum ImportHelpers {
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
