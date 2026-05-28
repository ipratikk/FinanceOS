import Foundation

public struct HDFCBankMetadataExtractor: Sendable {
    public init() {}

    public func extract(from content: String) -> StatementMetadata {
        let lines = content.components(separatedBy: .newlines)

        let customerName = extractCustomerName(from: lines)
        let accountLast4 = extractAccountLast4(from: lines)
        let fullAccountNumber = extractFullAccountNumber(from: lines)
        let accountType = extractAccountType(from: lines)
        let statementDate = extractStatementDate(from: lines)

        let openingBalance = extractOpeningBalance(from: content)

        return StatementMetadata(
            customerName: customerName,
            accountNumber: accountLast4,
            fullAccountNumber: fullAccountNumber,
            accountType: accountType,
            cardType: nil,
            openingBalance: openingBalance,
            generatedAt: statementDate
        )
    }

    /// Derives opening balance from the first data row:
    /// opening = closing_balance + debit - credit
    private func extractOpeningBalance(from content: String) -> Int64? {
        if content.components(separatedBy: .newlines).contains(where: { $0.hasPrefix("--------  ---") }) {
            return extractOpeningBalanceFixedWidth(from: content)
        }
        return extractOpeningBalanceDelimited(from: content)
    }

    private func extractOpeningBalanceDelimited(from content: String) -> Int64? {
        let lines = content.components(separatedBy: .newlines)
        var headerIdx: Int?
        var closingCol: Int?
        var debitCol: Int?
        var creditCol: Int?

        for (idx, line) in lines.enumerated() {
            let parts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            guard parts.contains(where: { $0.contains("narration") }),
                  parts.contains(where: { $0.contains("closing balance") }) else { continue }
            headerIdx = idx
            closingCol = parts.firstIndex(where: { $0.contains("closing balance") })
            debitCol = parts.firstIndex(where: { $0 == "debit amount" || $0 == "debit" })
            creditCol = parts.firstIndex(where: { $0 == "credit amount" || $0 == "credit" })
            break
        }

        guard let hi = headerIdx, let cbCol = closingCol, let dCol = debitCol, let crCol = creditCol else {
            return nil
        }

        for line in lines.dropFirst(hi + 1) {
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            let parts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count > max(cbCol, dCol, crCol) else { continue }
            guard let closing = parseAmountToMinorUnits(parts[cbCol]),
                  let debit = parseAmountToMinorUnits(parts[dCol]),
                  let credit = parseAmountToMinorUnits(parts[crCol]) else { continue }
            return closing + debit - credit
        }
        return nil
    }

    private func extractOpeningBalanceFixedWidth(from content: String) -> Int64? {
        let lines = content.components(separatedBy: .newlines)
        guard let sepLine = lines.first(where: { $0.hasPrefix("--------  ---") }) else { return nil }
        let ranges = columnRangesFromSeparator(sepLine)
        guard ranges.count >= 7 else { return nil }

        var sepCount = 0
        var pastData = false
        for line in lines {
            if line.hasPrefix("--------  ---") {
                sepCount += 1
                if sepCount >= 2 { pastData = true }
                continue
            }
            guard pastData else { continue }
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            let dateField = extractField(line, ranges[0])
            guard !dateField.isEmpty else { continue }
            let withdrawal = parseAmountToMinorUnits(extractField(line, ranges[4])) ?? 0
            let deposit = parseAmountToMinorUnits(extractField(line, ranges[5])) ?? 0
            guard let closing = parseAmountToMinorUnits(extractField(line, ranges[6])) else { continue }
            return closing + withdrawal - deposit
        }
        return nil
    }

    private func columnRangesFromSeparator(_ separator: String) -> [(Int, Int)] {
        var ranges: [(Int, Int)] = []
        var inDash = false
        var start = 0
        for (i, ch) in separator.enumerated() {
            if ch == "-", !inDash { start = i; inDash = true } else if ch != "-", inDash {
                ranges.append((start, i)); inDash = false
            }
        }
        if inDash { ranges.append((start, separator.count)) }
        return ranges
    }

    private func extractField(_ line: String, _ range: (Int, Int)) -> String {
        let chars = Array(line.unicodeScalars)
        let start = min(range.0, chars.count)
        let end = min(range.1, chars.count)
        guard start < end else { return "" }
        return String(String.UnicodeScalarView(chars[start ..< end])).trimmingCharacters(in: .whitespaces)
    }

    private func parseAmountToMinorUnits(_ raw: String) -> Int64? {
        let cleaned = raw.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
        guard let value = Double(cleaned) else { return nil }
        return Int64((value * 100).rounded())
    }

    private func extractCustomerName(from lines: [String]) -> String? {
        for line in lines.prefix(100) {
            if line.contains("Customer Name") || line.contains("NAME~|~") {
                let parts = line.components(separatedBy: "~|~")
                if parts.count >= 2 {
                    return parts[1].trimmingCharacters(in: .whitespaces)
                } else if line.contains("Customer Name") {
                    let colonParts = line.components(separatedBy: ":")
                    if colonParts.count >= 2 {
                        return colonParts[1].trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        // Fixed-width: "MR      PRATIK GOEL                    SOUTH 24 PARGANAS"
        // Left column is the name; split at first double-space to strip right-column address.
        for line in lines.prefix(100) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            for title in ["MR ", "MRS ", "MS ", "DR ", "MR. ", "MRS. "] {
                if trimmed.uppercased().hasPrefix(title) {
                    let afterTitle = String(trimmed.dropFirst(title.count)).trimmingCharacters(in: .whitespaces)
                    let leftColumn = afterTitle.components(separatedBy: "  ").first ?? afterTitle
                    let name = leftColumn.components(separatedBy: .whitespaces)
                        .filter { !$0.isEmpty }.joined(separator: " ")
                    if !name.isEmpty { return name }
                }
            }
        }
        return nil
    }

    private func extractAccountLast4(from lines: [String]) -> String? {
        for line in lines.prefix(100) {
            if line.contains("Account"), line.contains("XXXXXXXX") {
                let pattern = "XXXXXXXX(\\d{4})"
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                   let matchRange = Range(match.range(at: 1), in: line) {
                    return String(line[matchRange])
                }
            }
        }
        // Fixed-width: "... Account No     : 50100375476521   VIRTUAL PREFERRED"
        // Line has multiple colons; find colon immediately after "Account No" label
        if let digits = extractAccountDigits(from: lines, minLength: 4) {
            return String(digits.suffix(4))
        }
        return nil
    }

    private func extractFullAccountNumber(from lines: [String]) -> String? {
        for line in lines.prefix(100) {
            if line.contains("Account"), line.contains("XXXXXXXX") {
                let pattern = "([0-9X]{12,})"
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                   let matchRange = Range(match.range(at: 1), in: line) {
                    return String(line[matchRange])
                }
            }
        }
        return extractAccountDigits(from: lines, minLength: 10)
    }

    /// Finds "Account No" label, then extracts the digit string after the following colon
    private func extractAccountDigits(from lines: [String], minLength: Int) -> String? {
        for line in lines.prefix(100) {
            guard line.contains("Account No") else { continue }
            guard let labelRange = line.range(of: "Account No") else { continue }
            let afterLabel = String(line[labelRange.upperBound...])
            guard let colonRange = afterLabel.range(of: ":") else { continue }
            let value = String(afterLabel[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            let token = value.components(separatedBy: .whitespaces).first ?? ""
            let digits = token.filter(\.isNumber)
            if digits.count >= minLength { return digits }
        }
        return nil
    }

    private func extractAccountType(from lines: [String]) -> String? {
        for line in lines.prefix(100) {
            let lower = line.lowercased()
            if lower.contains("account type") || lower.contains("type~|~") {
                let parts = line.components(separatedBy: "~|~")
                if parts.count >= 2 {
                    return parts[1].trimmingCharacters(in: .whitespaces)
                } else {
                    let colonParts = line.components(separatedBy: ":")
                    if colonParts.count >= 2 {
                        return colonParts[1].trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        return nil
    }

    private func extractStatementDate(from lines: [String]) -> Date? {
        for line in lines.prefix(100) {
            // Delimited format: "Statement Date : dd/MM/yyyy" or "Statement Period : ..."
            if line.contains("Statement Date") || line.contains("Statement Period") {
                let colonParts = line.components(separatedBy: ":")
                if colonParts.count >= 2 {
                    let dateString = colonParts[1].trimmingCharacters(in: .whitespaces)
                    if let date = parseDate(dateString) { return date }
                }
            }
            // Fixed-width format: "Statement From      : 01/04/2025  To: 31/03/2026  ..."
            if line.contains("Statement From") {
                if let toRange = line.range(of: "To:") ?? line.range(of: "TO:") {
                    let afterTo = String(line[toRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                    let token = afterTo.components(separatedBy: .whitespaces).first ?? ""
                    if let date = parseDate(token) { return date }
                }
            }
        }
        return nil
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formats = ["dd/MM/yyyy", "dd/MM/yy", "dd-MMM-yyyy"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }
}
