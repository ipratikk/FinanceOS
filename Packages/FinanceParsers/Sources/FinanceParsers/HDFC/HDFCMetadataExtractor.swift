import Foundation

private struct FooterTotals {
    let openingBalance: Int64?
    let closingBalance: Int64?
    let debitCount: Int?
    let creditCount: Int?
}

/// Extracts statement-level metadata (customer info, balances, counts)
/// from the header/footer rows of an HDFC bank statement.
///
/// Input: Vision OCR lines for the entire PDF (top-down reading order).
/// Output: `StatementMetadata` with best-effort field extraction. All
/// fields are optional — missing matches yield `nil`, never errors.
public struct HDFCMetadataExtractor: Sendable {
    public init() {}

    public func extract(from lines: [String]) -> StatementMetadata {
        let scalars = extractScalarFields(from: lines)
        let (customerName, address) = extractCustomerNameAndAddress(from: lines)
        let totals = extractFooterTotals(from: lines)
        let openingBalance = totals.openingBalance
        let closingBalance = totals.closingBalance
        let debitCount = totals.debitCount
        let creditCount = totals.creditCount
        let generatedAt = extractGeneratedAt(from: lines)

        return StatementMetadata(
            customerName: customerName,
            customerId: scalars.customerId,
            accountNumber: scalars.accountNumber,
            fullAccountNumber: nil,
            accountType: scalars.accountType,
            cardType: nil,
            branch: scalars.branch,
            branchCode: scalars.branchCode,
            address: address,
            email: scalars.email,
            phone: scalars.phone,
            ifsc: scalars.ifsc,
            micr: scalars.micr,
            openingBalance: openingBalance,
            closingBalance: closingBalance,
            debitCount: debitCount,
            creditCount: creditCount,
            generatedAt: generatedAt
        )
    }

    // MARK: - Scalar field extraction

    private struct ScalarFields {
        var customerId: String?
        var accountNumber: String?
        var accountType: String?
        var branch: String?
        var branchCode: String?
        var email: String?
        var phone: String?
        var ifsc: String?
        var micr: String?
    }

    private func extractScalarFields(from lines: [String]) -> ScalarFields {
        var fields = ScalarFields()
        for line in lines {
            applyScalarMatches(line: line, into: &fields)
        }
        return fields
    }

    private func applyScalarMatches(line: String, into fields: inout ScalarFields) {
        if fields.customerId == nil, let v = matchAfter(label: "Cust ID", in: line) {
            fields.customerId = v.firstWord
        }
        if fields.accountNumber == nil, let v = matchAfter(label: "Account No", in: line) {
            fields.accountNumber = v.leadingDigits
        }
        if fields.accountType == nil, let v = matchAfter(label: "Account Type", in: line) {
            fields.accountType = v
        }
        if fields.branch == nil, let v = matchAfter(label: "Account Branch", in: line) {
            fields.branch = v
        }
        if fields.branchCode == nil, let v = matchAfter(label: "Branch Code", in: line) {
            fields.branchCode = v.firstWord
        }
        if fields.ifsc == nil, let v = matchIFSC(in: line) {
            fields.ifsc = v
        }
        if fields.micr == nil, let v = matchAfter(label: "MICR", in: line) {
            fields.micr = v.firstWord
        }
        if fields.email == nil, let v = matchAfter(label: "Email", in: line) {
            fields.email = v.firstWord
        }
        if fields.phone == nil, let v = matchPhone(in: line) {
            fields.phone = v
        }
    }

    private func matchAfter(label: String, in line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let range = trimmed.range(of: label, options: .caseInsensitive) else { return nil }
        let afterLabel = trimmed[range.upperBound...]
        // Expect a colon separator
        guard let colonIdx = afterLabel.firstIndex(of: ":") else { return nil }
        let value = afterLabel[afterLabel.index(after: colonIdx)...].trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }

    private func matchIFSC(in line: String) -> String? {
        // Matches "RTGS/NEFT IFSC: HDFC0001931" or variations.
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.range(of: "IFSC", options: .caseInsensitive) != nil else { return nil }
        guard let colonIdx = trimmed.firstIndex(of: ":") else { return nil }
        let value = trimmed[trimmed.index(after: colonIdx)...].trimmingCharacters(in: .whitespaces)
        return value.firstWord
    }

    private func matchPhone(in line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.range(of: "Phone", options: .caseInsensitive) != nil else { return nil }
        guard let colonIdx = trimmed.firstIndex(of: ":") else { return nil }
        let value = trimmed[trimmed.index(after: colonIdx)...].trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : String(value)
    }

    // MARK: - Customer name + address

    private func extractCustomerNameAndAddress(from lines: [String]) -> (String?, String?) {
        // HDFC layout: customer name appears as the first all-caps line
        // before the "JOINT HOLDERS" marker (if present), followed by
        // address lines.
        guard let nameIdx = lines.firstIndex(where: isLikelyCustomerName) else {
            return (nil, nil)
        }
        let name = lines[nameIdx].trimmingCharacters(in: .whitespaces)

        let stopMarkers = ["JOINT HOLDERS", "Nomination", "Statement of account", "Cust ID"]
        var addressLines: [String] = []
        for i in (nameIdx + 1) ..< lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            // Skip stray punctuation-only lines (e.g. ".") that PDFKit emits
            if line.allSatisfy({ ".,-_ ".contains($0) }) { continue }
            if stopMarkers.contains(where: { line.range(of: $0, options: .caseInsensitive) != nil }) {
                break
            }
            // Stop if we hit a labelled field — address has ended
            if line.contains(":") { break }
            addressLines.append(line)
            if addressLines.count >= 6 { break }
        }
        let address = addressLines.isEmpty ? nil : addressLines.joined(separator: ", ")
        return (name, address)
    }

    private func isLikelyCustomerName(_ raw: String) -> Bool {
        let line = raw.trimmingCharacters(in: .whitespaces)
        guard line.count >= 4, line.count <= 80 else { return false }
        // Reject lines containing colons (labelled fields) or digits.
        if line.contains(":") { return false }
        if line.unicodeScalars.contains(where: { CharacterSet.decimalDigits.contains($0) }) { return false }
        // Must start with a salutation prefix or be entirely uppercase letters/spaces.
        let salutations = ["MR ", "MRS ", "MS ", "DR ", "MISS "]
        if salutations.contains(where: { line.uppercased().hasPrefix($0) }) {
            return line == line.uppercased()
        }
        return false
    }

    // MARK: - Footer totals

    private func extractFooterTotals(from lines: [String]) -> FooterTotals {
        // Locate the header row, then scan following lines for a row of
        // numeric tokens. The numeric row layout is:
        //   <opening> <drCount> <crCount> <debits> <credits> <closing>
        let empty = FooterTotals(openingBalance: nil, closingBalance: nil, debitCount: nil, creditCount: nil)
        guard let headerIdx = lines.firstIndex(where: isFooterHeaderLine) else { return empty }
        let endIdx = min(headerIdx + 6, lines.count)
        for i in (headerIdx + 1) ..< endIdx {
            if let parsed = parseFooterTotalsLine(lines[i]) { return parsed }
        }
        return empty
    }

    private func isFooterHeaderLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        return lower.contains("opening balance")
            && lower.contains("dr count")
            && lower.contains("cr count")
            && lower.contains("closing")
    }

    private func parseFooterTotalsLine(_ line: String) -> FooterTotals? {
        let tokens = line.split(separator: " ").map(String.init)
        // Expected: 6 numeric tokens. Two large amounts, two counts, debits+credits.
        let numeric = tokens.filter { isNumericToken($0) }
        guard numeric.count >= 6 else { return nil }
        return FooterTotals(
            openingBalance: parseAmountToMinorUnits(numeric[0]),
            closingBalance: parseAmountToMinorUnits(numeric[5]),
            debitCount: Int(numeric[1]),
            creditCount: Int(numeric[2])
        )
    }

    private func isNumericToken(_ s: String) -> Bool {
        let cleaned = s.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
        return !cleaned.isEmpty && cleaned.allSatisfy(\.isNumber)
    }

    // MARK: - Generated-at timestamp

    private func extractGeneratedAt(from lines: [String]) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd-MMM-yyyy HH:mm:ss"
        for line in lines {
            guard line.range(of: "Generated On", options: .caseInsensitive) != nil else { continue }
            guard let colonIdx = line.firstIndex(of: ":") else { continue }
            let value = line[line.index(after: colonIdx)...].trimmingCharacters(in: .whitespaces)
            if let date = formatter.date(from: value) { return date }
            // Fall back: tokenize and try first "dd-MMM-yyyy HH:mm:ss" window.
            let tokens = value.split(separator: " ").map(String.init)
            if tokens.count >= 2 {
                let candidate = tokens[0] + " " + tokens[1]
                if let date = formatter.date(from: candidate) { return date }
            }
        }
        return nil
    }

    // MARK: - Amount parsing

    private func parseAmountToMinorUnits(_ s: String) -> Int64? {
        let cleaned = s.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(cleaned) else { return nil }
        return Int64((value * 100).rounded())
    }
}

// MARK: - String helpers

private extension String {
    var firstWord: String? {
        let trimmed = trimmingCharacters(in: .whitespaces)
        guard let space = trimmed.firstIndex(of: " ") else {
            return trimmed.isEmpty ? nil : trimmed
        }
        let word = String(trimmed[..<space])
        return word.isEmpty ? nil : word
    }

    var leadingDigits: String? {
        let trimmed = trimmingCharacters(in: .whitespaces)
        var digits = ""
        for ch in trimmed {
            if ch.isNumber { digits.append(ch) } else { break }
        }
        return digits.isEmpty ? nil : digits
    }
}

private extension Substring {
    var firstWord: String? {
        String(self).firstWord
    }
}
