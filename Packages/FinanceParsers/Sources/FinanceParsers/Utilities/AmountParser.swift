import Foundation

public enum AmountParser {
    public static func parseToInt64(_ string: String) -> Int64? {
        let cleaned = string
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let decimal = Decimal(string: cleaned) else { return nil }

        let multiplied = decimal * 100
        guard !multiplied.isNaN && multiplied.isFinite else { return nil }

        return NSDecimalNumber(decimal: multiplied).int64Value
    }

    public static func parseAsSignedInt64(_ string: String) -> Int64? {
        parseToInt64(string)
    }

    public static func parseAsAbsoluteInt64(_ string: String) -> Int64? {
        guard let value = parseToInt64(string) else { return nil }
        return abs(value)
    }
}
