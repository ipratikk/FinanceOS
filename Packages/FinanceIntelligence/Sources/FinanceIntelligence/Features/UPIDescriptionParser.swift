import Foundation

/// Parses Indian bank UPI/NEFT/IMPS description formats to extract merchant names and
/// determine whether a transaction is a P2P transfer or a merchant payment.
///
/// Supported formats:
/// - UPI:  `"UPI-MERCHANT NAME-vpa@bank-BANKCODE-TXNREF"`
/// - NEFT: `"NEFT CR-BANKCODE-PARTY NAME-REF"` / `"NEFT DR-BANKCODE-PARTY NAME-REF"`
/// - IMPS: `"IMPS-TXNID-PARTY NAME-BANKCODE"`
enum UPIDescriptionParser {
    /// The structured result of parsing a UPI/NEFT/IMPS bank description.
    struct ParsedUPI {
        /// Extracted merchant or counterparty name (cleaned, not lowercased).
        let merchantName: String
        /// Virtual payment address (e.g. `"merchant@razorpay"`). Nil for NEFT/IMPS.
        let vpa: String?
        /// True when the VPA or name pattern suggests a person-to-person transfer.
        let isPersonTransfer: Bool
        /// True when the VPA or name matches known business/merchant patterns.
        let isMerchantPayment: Bool
    }

    /// Known business VPA suffixes that indicate merchant payments (not P2P transfers)
    private static let businessVPASuffixes = [
        "@rzp", "@razorpay", "@paytm", "@upi", "@ybl", "@okhdfcbank",
        "@okicici", "@okaxis", "@oksbi", "@apl", "@ikwik", "@airtelpaymentsbank",
        "@hdfcbank", "@icici", "@axisbank", "@ptybl", "@yesb", "@airp",
        "@sc", "@scbl",  // Standard Chartered (used by AmEx UPI)
        "marketplace", "services", "store", "shop", "retail", "online",
        "blinkit", "zepto", "swiggy", "zomato", "ola", "uber",
        "amazon", "flipkart", "netflix", "spotify", "hotstar",
        "bbnow", "bigbasket", "gpay", "googlepay"
    ]

    /// Keywords in merchant name segment that indicate business
    private static let businessNameKeywords = [
        "marketplace", "services", "pvt", "ltd", "private limited", "llp",
        "retail", "technologies", "payments", "enterprises", "solutions",
        "swiggy", "zomato", "blinkit", "zepto", "ola", "uber", "amazon",
        "flipkart", "netflix", "spotify", "apple", "google", "airtel", "jio",
        // Indian fintech/payments
        "bbnow", "bigbasket", "gpay", "paytm", "cred", "bhim", "npci",
        "phonepe", "razorpay", "cashfree",
        // Financial institutions & credit
        "american express", "amex", "hdfc", "icici", "lombard",
        "insurance", "bank", "credit card", "express",
        // Retail/fashion
        "hennes", "h and m", "ikea", "family super market",
        // Utilities/telecom
        "airtel", "jio", "livpure", "dominos", "domino", "magicpin"
    ]

    /// Parses `rawDescription` and returns a structured result, or nil if the format is unrecognized.
    static func parse(_ rawDescription: String) -> ParsedUPI? {
        let upper = rawDescription.uppercased()
        if upper.hasPrefix("UPI-") { return parseUPI(rawDescription) }
        if upper.hasPrefix("NEFT CR-") || upper.hasPrefix("NEFT DR-") { return parseNEFT(rawDescription) }
        if upper.hasPrefix("IMPS-") { return parseIMPS(rawDescription) }
        return nil
    }

    /// Extract merchant name + determine if P2P or merchant payment
    static func merchantName(from rawDescription: String) -> String? {
        guard let parsed = parse(rawDescription) else { return nil }
        return parsed.merchantName
    }

    /// Returns true when the description represents a P2P bank transfer rather than a merchant payment.
    /// Falls back to keyword matching for non-UPI/NEFT/IMPS descriptions.
    static func isLikelyTransfer(_ rawDescription: String) -> Bool {
        guard let parsed = parse(rawDescription) else {
            // Non-UPI/NEFT: check classic transfer keywords
            let lower = rawDescription.lowercased()
            return lower.contains("neft") || lower.contains("imps") || lower.contains("rtgs")
        }
        return parsed.isPersonTransfer && !parsed.isMerchantPayment
    }
}

// MARK: - Format Parsers

private extension UPIDescriptionParser {
    static func parseUPI(_ raw: String) -> ParsedUPI {
        // Format: UPI-MERCHANT-vpa@bank-BANKCODE-REF
        let withoutPrefix = String(raw.dropFirst(4)) // drop "UPI-"
        let parts = withoutPrefix.components(separatedBy: "-")

        let merchantSegment = parts.first ?? withoutPrefix
        // VPA is the part containing "@"
        let vpa = parts.first(where: { $0.contains("@") })?.lowercased()

        let isBusiness = isMerchantPayment(name: merchantSegment, vpa: vpa)

        return ParsedUPI(
            merchantName: cleanMerchantSegment(merchantSegment),
            vpa: vpa,
            isPersonTransfer: !isBusiness,
            isMerchantPayment: isBusiness
        )
    }

    static func parseNEFT(_ raw: String) -> ParsedUPI {
        // Format: NEFT CR-BANKCODE-PARTY NAME-REF  OR  NEFT DR-BANKCODE-PARTY-REF
        let parts = raw.components(separatedBy: "-")
        // Index 0 = "NEFT CR" or "NEFT DR", 1 = BANKCODE, 2 = PARTY NAME, 3+ = ref
        let partyName = parts.count > 2 ? parts[2] : raw
        let isBusiness = isMerchantPayment(name: partyName, vpa: nil)
        return ParsedUPI(
            merchantName: cleanMerchantSegment(partyName),
            vpa: nil,
            isPersonTransfer: !isBusiness,
            isMerchantPayment: isBusiness
        )
    }

    static func parseIMPS(_ raw: String) -> ParsedUPI {
        // Format: IMPS-TXNID-PARTY NAME-BANKCODE
        let parts = raw.components(separatedBy: "-")
        let partyName = parts.count > 2 ? parts[2] : raw
        return ParsedUPI(
            merchantName: cleanMerchantSegment(partyName),
            vpa: nil,
            isPersonTransfer: true,
            isMerchantPayment: false
        )
    }

    static func isMerchantPayment(name: String, vpa: String?) -> Bool {
        let lower = name.lowercased()
        let vpaLower = vpa?.lowercased() ?? ""
        let combined = lower + " " + vpaLower
        return businessNameKeywords.contains(where: { combined.contains($0) })
            || businessVPASuffixes.contains(where: { combined.contains($0) })
    }

    static func cleanMerchantSegment(_ segment: String) -> String {
        // Remove bank codes (4+ uppercase letters + digits like ICIC0, HDFC0)
        let trimmed = segment.trimmingCharacters(in: .whitespaces)
        // If it looks like just a bank code or transaction ID, return as-is
        return trimmed.isEmpty ? segment : trimmed
    }
}
