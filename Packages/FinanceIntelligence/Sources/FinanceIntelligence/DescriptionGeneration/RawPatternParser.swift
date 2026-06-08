import FinanceCore
import Foundation

/// Deterministic parser for structured opaque bank description formats.
/// Returns a human-readable label when the raw bank string matches a known pattern.
/// Returns `nil` for unrecognised formats — caller falls back to FallbackGenerator.
///
/// Handled patterns:
///   - INW inward remittance:  `INW {ref} {CURR}{amount}@{rate}`
///   - DPO GST charge:         `{ref} DPO{code} IGST|CGST|SGST`
///   - IGST-VPS bank charge:   `IGST|CGST|SGST-VPS{code}- RATE {rate} ...`
///   - GST slash charge:       `GST/IGST@{rate}%`
///   - Interest credit:        `INTEREST PAID TILL {DD}-{MON}-{YYYY}` / `:Int.Pd:` range
///   - Recurring bank fees:    `SMSChgs...` / `DCARDFEE...`
///   - NEFT salary credit:     `NEFT CR-...SALARY FOR {MONTH} {YEAR}`
///   - Rent payment:           `...HOUSE RENT` / trailing `RENT ...` remark
public struct RawPatternParser: Sendable {
    public init() {}

    public func parse(_ rawDescription: String, merchantName: String) -> String? {
        let upper = rawDescription.uppercased()
        if let result = parseINW(upper) { return result }
        if let result = parseDPOTax(upper) { return result }
        if let result = parseIGSTVPS(upper) { return result }
        if let result = parseGSTSlash(upper) { return result }
        if let result = parseInterest(upper) { return result }
        if let result = parseInterestPaidRange(upper) { return result }
        if let result = parseBankCharge(upper) { return result }
        if let result = parseNEFTSalary(upper, merchantName: merchantName) { return result }
        if let result = parseRent(upper, merchantName: merchantName) { return result }
        return nil
    }

    // MARK: - Cached patterns (compiled once)

    /// Patterns are compile-time constant literals, so compilation cannot fail.
    private static func regex(_ pattern: String) -> NSRegularExpression {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: pattern)
    }

    // Currency block anchored to a word boundary so it cannot match letters glued
    // mid-token (e.g. a reference suffix); only a real `{CURR}{amount}@{rate}` block matches.
    private static let inwRegex = regex(#"(?:^|\s)([A-Z]{3})([\d.]+)@([\d.]+)"#)
    private static let dpoTaxRegex = regex(#"DPO\w+\s+(IGST|CGST|SGST)"#)
    private static let igstVpsRateRegex = regex(#"RATE\s+([\d.]+)"#)
    private static let gstSlashRegex = regex(#"GST/(IGST|CGST|SGST)@([\d.]+)"#)
    private static let interestDateRegex =
        regex(#"\d+-(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)-(\d{4})"#)
    private static let salaryRegex = regex(#"SALARY FOR\s+([A-Z]+)\s+(\d+)"#)

    /// Returns the captured groups (1…n) of the first match, or nil if no match.
    private func captures(_ regex: NSRegularExpression, in text: String) -> [String]? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        var groups: [String] = []
        for index in 1 ..< match.numberOfRanges {
            guard let groupRange = Range(match.range(at: index), in: text) else { return nil }
            groups.append(String(text[groupRange]))
        }
        return groups
    }

    // MARK: - Patterns (operate on the already-uppercased string)

    private func parseINW(_ upper: String) -> String? {
        guard upper.hasPrefix("INW "),
              let groups = captures(Self.inwRegex, in: upper), groups.count == 3,
              let amount = Double(groups[1]), let rate = Double(groups[2]) else { return nil }
        let minorUnits = Int64((amount * 100).rounded())
        let amountText = MoneyFormatting.formatRunningBalance(minorUnits: minorUnits, currencyCode: groups[0])
        let rupee = CurrencySymbol.symbol(for: "INR")
        return "Inward Remittance · \(amountText) @ \(rupee)\(String(format: "%.2f", rate))"
    }

    private func parseDPOTax(_ upper: String) -> String? {
        guard upper.contains("DPO"), let groups = captures(Self.dpoTaxRegex, in: upper) else { return nil }
        return "\(groups[0]) on Wire Transfer"
    }

    private func parseIGSTVPS(_ upper: String) -> String? {
        guard let taxType = ["IGST", "CGST", "SGST"].first(where: { upper.hasPrefix("\($0)-VPS") }) else { return nil }
        guard let groups = captures(Self.igstVpsRateRegex, in: upper), let rate = Double(groups[0]) else {
            return "\(taxType) on Bank Charges"
        }
        return "\(taxType) · \(formatRate(rate))% on Bank Charges"
    }

    /// Slash-form GST charge: `GST/IGST@18%` → `IGST · 18% on Bank Charges`.
    private func parseGSTSlash(_ upper: String) -> String? {
        guard let groups = captures(Self.gstSlashRegex, in: upper), let rate = Double(groups[1]) else { return nil }
        return "\(groups[0]) · \(formatRate(rate))% on Bank Charges"
    }

    private func parseInterest(_ upper: String) -> String? {
        guard upper.hasPrefix("INTEREST PAID TILL ") else { return nil }
        guard let groups = captures(Self.interestDateRegex, in: upper) else { return "Bank Interest" }
        return "Bank Interest · \(monthName(groups[0])) \(groups[1])"
    }

    /// Quarterly interest-paid range: `...:Int.Pd:29-03-2025 to 29-06-2025` → `Bank Interest`.
    private func parseInterestPaidRange(_ upper: String) -> String? {
        upper.contains("INT.PD") ? "Bank Interest" : nil
    }

    /// Recurring bank fees with embedded GST: SMS alert charges and debit-card fees.
    private func parseBankCharge(_ upper: String) -> String? {
        if upper.hasPrefix("SMSCHGS") { return "SMS Charges" }
        if upper.hasPrefix("DCARDFEE") { return "Debit Card Fee" }
        return nil
    }

    private func parseNEFTSalary(_ upper: String, merchantName: String) -> String? {
        guard upper.hasPrefix("NEFT CR"), upper.contains("SALARY FOR") else { return nil }
        guard let groups = captures(Self.salaryRegex, in: upper) else {
            return merchantName.isEmpty ? "Salary" : "Salary from \(merchantName)"
        }
        let from = merchantName.isEmpty ? "" : " from \(merchantName)"
        return "Salary\(from) · \(groups[0].capitalized) \(groups[1])"
    }

    /// Detects an explicit rent remark in the raw bank string.
    /// Matches `HOUSE RENT` anywhere, or the last non-empty hyphen segment being exactly
    /// `RENT` or beginning with `RENT ` (e.g. "RENT MARCH", "RENT 1804 T2"). Skipping trailing
    /// empty segments handles a dangling `-`; prefix matching avoids CURRENT / PARENT / RENTAL.
    private func parseRent(_ upper: String, merchantName: String) -> String? {
        let lastRemark = upper.components(separatedBy: "-")
            .reversed()
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty } ?? ""
        let isRent = upper.contains("HOUSE RENT") || lastRemark == "RENT" || lastRemark.hasPrefix("RENT ")
        guard isRent else { return nil }
        return merchantName.isEmpty ? "House Rent" : "House Rent · \(merchantName)"
    }

    // MARK: - Helpers

    /// Formats a percentage rate without a trailing `.0` (18.0 → "18", 9.5 → "9.5").
    private func formatRate(_ rate: Double) -> String {
        rate.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(rate)) : String(format: "%.1f", rate)
    }

    private static let monthNames: [String: String] = [
        "JAN": "January", "FEB": "February", "MAR": "March", "APR": "April",
        "MAY": "May", "JUN": "June", "JUL": "July", "AUG": "August",
        "SEP": "September", "OCT": "October", "NOV": "November", "DEC": "December"
    ]

    private func monthName(_ abbrev: String) -> String {
        Self.monthNames[abbrev] ?? abbrev.capitalized
    }
}
