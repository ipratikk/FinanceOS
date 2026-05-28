import Foundation

enum AnalyticsFormatting {
    private static let decimalFormatter: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.groupingSeparator = ","
        fmt.maximumFractionDigits = 0
        fmt.minimumFractionDigits = 0
        return fmt
    }()

    private static let decimalTwoFmt: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.groupingSeparator = ","
        fmt.maximumFractionDigits = 2
        fmt.minimumFractionDigits = 2
        return fmt
    }()

    static func rupees(_ minorUnits: Int64) -> String {
        let value = Double(minorUnits) / 100.0
        let str = decimalFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "₹\(str)"
    }

    static func rupeesWithSign(_ minorUnits: Int64, isDebit: Bool) -> String {
        let value = Double(minorUnits) / 100.0
        let str = decimalTwoFmt.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        let sign = isDebit ? "" : "+"
        return "\(sign)₹\(str)"
    }
}
