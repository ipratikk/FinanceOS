import Foundation

// MARK: - ICICIMetadataExtractor

/// Extracts statement-level metadata from ICICI bank CSV rows.
///
/// Customer name comes from the first cell of the first row; address follows in subsequent rows
/// until a "STATEMENT" keyword is encountered. Account details are parsed from a cell matching
/// `"XXXXXXXX<4digits>"` with account type keywords (Savings/PPF/Current).
public struct ICICIMetadataExtractor: Sendable {
    public init() {}

    public func extract(from rows: [[String]]) -> StatementMetadata {
        let (customerName, address) = extractCustomerNameAndAddress(from: rows)
        let (customerId, statementDate) = extractCustomerIdAndDate(from: rows)
        let accountDetails = extractAccountDetails(from: rows)

        return StatementMetadata(
            customerName: customerName,
            customerId: customerId,
            accountNumber: accountDetails.accountNumber,
            fullAccountNumber: nil,
            accountType: accountDetails.accountType,
            cardType: nil,
            address: address,
            closingBalance: accountDetails.balance,
            generatedAt: statementDate
        )
    }

    // MARK: - Customer name and address

    private func extractCustomerNameAndAddress(from rows: [[String]]) -> (String?, String?) {
        guard !rows.isEmpty else { return (nil, nil) }

        let firstCell = rows[0].first ?? ""
        let name = firstCell.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return (nil, nil) }

        var addressLines: [String] = []
        var rowIndex = 1
        while rowIndex < rows.count && addressLines.count < 5 {
            guard let firstCol = rows[rowIndex].first else {
                rowIndex += 1
                continue
            }
            let line = firstCol.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty {
                rowIndex += 1
                continue
            }
            if line.uppercased().contains("STATEMENT") {
                break
            }
            addressLines.append(line)
            rowIndex += 1
        }

        let address = addressLines.isEmpty ? nil : addressLines.joined(separator: ", ")
        return (name, address)
    }

    // MARK: - Customer ID and statement date

    private func extractCustomerIdAndDate(from rows: [[String]]) -> (String?, Date?) {
        for row in rows {
            let joined = row.joined(separator: " ")
            if joined.uppercased().contains("STATEMENT SUMMARY"), joined.uppercased().contains("CUSTOMER ID") {
                let customerId = extractCustomerIdValue(from: joined)
                let dateStr = extractDateFromSummary(from: joined)
                let date = parseStatementDate(dateStr)
                return (customerId, date)
            }
        }
        return (nil, nil)
    }

    private func extractCustomerIdValue(from text: String) -> String? {
        if let range = text.range(of: "Customer ID", options: .caseInsensitive) {
            let after = text[range.upperBound...].trimmingCharacters(in: .whitespaces)
            if let colonIdx = after.firstIndex(of: ":") {
                let value = after[after.index(after: colonIdx)...].trimmingCharacters(in: .whitespaces)
                let idPart = value.components(separatedBy: " ").first ?? ""
                return idPart.isEmpty ? nil : idPart
            }
        }
        return nil
    }

    private func extractDateFromSummary(from text: String) -> String? {
        if let range = text.range(of: "as on", options: .caseInsensitive) {
            let after = text[range.upperBound...].trimmingCharacters(in: .whitespaces)
            let components = after.components(separatedBy: " ").filter { !$0.isEmpty }
            if components.count >= 3 {
                return components[0] + " " + components[1] + " " + components[2]
            }
        }
        return nil
    }

    // MARK: - Account details

    private struct AccountDetails {
        var accountNumber: String?
        var accountType: String?
        var balance: Int64?
    }

    private func extractAccountDetails(from rows: [[String]]) -> AccountDetails {
        var details = AccountDetails()

        for (idx, row) in rows.enumerated() {
            guard idx < 20 else { break }

            let firstCol = (row.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            if firstCol.contains("XXXXXXXX"), firstCol.contains("A/c") {
                if let number = extractAccountNumberFromCell(firstCol) {
                    details.accountNumber = number
                }
                if let type = extractAccountTypeFromCell(firstCol) {
                    details.accountType = type
                }
                if row.count >= 2 {
                    let balanceCell = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if let amt = parseAmountToMinorUnits(balanceCell) {
                        details.balance = amt
                    }
                }
                // Savings is the primary account type — stop here
                if details.accountType == "Savings" {
                    break
                }
            }
        }

        return details
    }

    private func extractAccountNumberFromCell(_ text: String) -> String? {
        let pattern = "XXXXXXXX(\\d{4})"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range) {
                if let matchRange = Range(match.range(at: 1), in: text) {
                    return String(text[matchRange])
                }
            }
        }
        return nil
    }

    private func extractAccountTypeFromCell(_ text: String) -> String? {
        let lower = text.lowercased()
        if lower.contains("ppf") {
            return "PPF"
        } else if lower.contains("savings") {
            return "Savings"
        } else if lower.contains("current") {
            return "Current"
        }
        return nil
    }

    // MARK: - Date parsing

    private func extractDateValue(from text: String) -> String? {
        let components = text.components(separatedBy: " ")
        for componentIdx in 0 ..< components.count {
            let comp = components[componentIdx]
            if comp.lowercased() == "on" || comp.lowercased() == "as" {
                if componentIdx + 2 < components.count {
                    return "\(components[componentIdx + 1]) \(components[componentIdx + 2])"
                }
            }
        }
        return nil
    }

    private func parseStatementDate(_ dateStr: String?) -> Date? {
        guard let dateStr else { return nil }
        return DateParser.parse(dateStr, formats: [
            "MMMM dd yyyy", "MMMM d yyyy", "MMM dd yyyy", "MMM d yyyy",
            "dd-MMM-yyyy", "dd/MM/yyyy"
        ])
    }

    // MARK: - Amount parsing

    private func parseAmountToMinorUnits(_ amountString: String) -> Int64? {
        let cleaned = amountString.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(cleaned) else { return nil }
        return Int64((value * 100).rounded())
    }
}
