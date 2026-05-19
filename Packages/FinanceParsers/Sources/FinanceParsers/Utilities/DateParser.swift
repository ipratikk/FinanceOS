import Foundation

public enum DateParser {
    private static let formatter = DateFormatter()

    public static func parse(_ string: String, formats: [String]) -> Date? {
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }

    public static func parseICICIBank(_ string: String) -> Date? {
        parse(string, formats: ["dd-MM-yyyy"])
    }

    public static func parseICICICard(_ string: String) -> Date? {
        parse(string, formats: ["dd/MM/yyyy"])
    }

    public static func parseHDFCBank(_ string: String) -> Date? {
        parse(string, formats: ["dd/MM/yy"])
    }

    public static func parseHDFCCard(_ string: String) -> Date? {
        parse(string, formats: ["dd/MM/yyyy HH:mm:ss"])
    }

    public static func parseAmex(_ string: String) -> Date? {
        parse(string, formats: ["MM/dd/yyyy"])
    }

    public static func parseAxisBank(_ string: String) -> Date? {
        parse(string, formats: ["dd/MM/yyyy", "dd-MMM-yyyy"])
    }

    public static func parseSBIBank(_ string: String) -> Date? {
        parse(string, formats: ["dd/MM/yyyy", "dd-MMM-yyyy"])
    }
}
