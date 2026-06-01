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

    /// VPA infixes/suffixes that are exclusively merchant payment gateways.
    /// IMPORTANT: personal bank VPAs like @okhdfcbank, @okicici, @ybl are NOT here
    /// because both persons (9051481667@okhdfcbank) AND merchants use them.
    /// Only true merchant-only gateways belong here.
    private static let merchantGatewayVPATokens = [
        "@rzp", "@razorpay", // Razorpay — never a personal VPA
        ".rzp", // Razorpay infix (e.g. blinkit104020.rzp@rxairtel)
        "bdsi@", // BillDesk — Apple, Spotify, Hotstar use this
        ".payu@", // PayU gateway (merchants only)
        "@ptybl", // Paytm merchant gateway (distinct from personal @paytm)
        "@ptys", // Paytm Bharat QR / SoundBox merchant gateway
        "@okbizaxis" // Axis Bank business UPI (distinct from personal @okaxis)
    ]

    /// Keywords in merchant name segment that indicate business
    private static let businessNameKeywords = [
        "marketplace", "services", "pvt", "ltd", "private limited", "llp",
        "retail", "technologies", "payments", "enterprises", "solutions",
        "traders", "trading", "agency", "distributors", "supplier",
        "swiggy", "zomato", "blinkit", "zepto", "ola", "uber", "amazon",
        "flipkart", "netflix", "spotify", "apple", "google", "airtel", "jio",
        // Indian fintech/payments
        "bbnow", "bigbasket", "gpay", "paytm", "cred", "bhim", "npci",
        "phonepe", "razorpay", "cashfree",
        // Financial institutions & credit
        "american express", "amex", "hdfc", "icici", "lombard",
        "insurance", "bank", "credit card", "express",
        // Retail/fashion/food
        "hennes", "h and m", "ikea", "family super market",
        "bawarchi", "mcdonald", "kfc", "subway", "pizza hut", "haldiram",
        // Utilities/telecom
        "airtel", "jio", "livpure", "dominos", "domino", "magicpin"
    ]

    /// Parses `rawDescription` and returns a structured result, or nil if the format is unrecognized.
    static func parse(_ rawDescription: String) -> ParsedUPI? {
        let upper = rawDescription.uppercased()
        if upper.hasPrefix("UPI-") { return parseUPI(rawDescription) }
        // "UPI/fromVPA/remarks/bank/..." — incoming UPI credit format used by HDFC
        if upper.hasPrefix("UPI/") { return parseUPISlash(rawDescription) }
        if upper.hasPrefix("UPL/") { return parseUPISlash(rawDescription) } // UPI Lite
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

    /// Format: "UPI/{fromVPA}/{remarks}/{bank}/{txnId}/{ref}" — HDFC incoming credit format
    static func parseUPISlash(_ raw: String) -> ParsedUPI {
        let parts = raw.components(separatedBy: "/")
        // parts[0] = "UPI", parts[1] = fromVPA (e.g. "9007649019@upi"), parts[2] = remarks
        let vpa = parts.count > 1 ? parts[1].lowercased() : nil
        let remarks = parts.count > 2 ? parts[2] : ""
        // Derive name: use remarks if meaningful, else derive from VPA prefix
        let name: String = if !remarks.isEmpty, remarks.uppercased() != "NO REMARKS", remarks.uppercased() != "UPI" {
            remarks
        } else if let vpaPrefix = vpa?.components(separatedBy: "@").first, !vpaPrefix.isEmpty {
            vpaPrefix
        } else {
            raw
        }
        let isBusiness = isMerchantPayment(name: name, vpa: vpa)
        return ParsedUPI(
            merchantName: cleanMerchantSegment(name),
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
        let isBusiness = isMerchantPayment(name: partyName, vpa: nil)
        return ParsedUPI(
            merchantName: cleanMerchantSegment(partyName),
            vpa: nil,
            isPersonTransfer: !isBusiness,
            isMerchantPayment: isBusiness
        )
    }

    static func isMerchantPayment(name: String, vpa: String?) -> Bool {
        let lower = name.lowercased()
        let vpaLower = vpa?.lowercased() ?? ""

        // Phone-number VPA prefix → always a person.
        // Handles 10-digit (9051481667@upi) and 12-digit with 91 country code (918129588782@federal).
        if let vpaPrefix = vpa?.components(separatedBy: "@").first, vpaPrefix.allSatisfy(\.isNumber) {
            if vpaPrefix.count == 10 { return false }
            if vpaPrefix.count == 12, vpaPrefix.hasPrefix("91") { return false }
        }

        // Merchant gateway VPA tokens — only true payment gateways, not personal banks
        if merchantGatewayVPATokens.contains(where: { vpaLower.contains($0) }) {
            return true
        }

        // Business name keywords in the merchant name segment
        return businessNameKeywords.contains(where: { lower.contains($0) })
    }

    static func cleanMerchantSegment(_ segment: String) -> String {
        // Remove bank codes (4+ uppercase letters + digits like ICIC0, HDFC0)
        let trimmed = segment.trimmingCharacters(in: .whitespaces)
        // If it looks like just a bank code or transaction ID, return as-is
        return trimmed.isEmpty ? segment : trimmed
    }
}
