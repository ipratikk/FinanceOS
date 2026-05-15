//
//  HDFCLineClassifier.swift
//  FinanceCore
//
//  Created by Pratik Goel on 15/05/26.
//

import Foundation

// Models defined in HDFCStatementModels.swift
// ClassifiedLine, StatementLinePurpose, etc.

class HDFCLineClassifier {
    private let datePattern = "\\d{2}/\\d{2}/\\d{2}"
    private let amountPattern = "\\d{1,3}(,\\d{3})*\\.\\d{2}"
    private let balancePattern = "Balance[:\\s]+\\d{1,3}(,\\d{3})*\\.\\d{2}"
    private let headerKeywords = ["date", "narration", "debit", "credit", "balance", "ref", "chq"]
    private let footerKeywords = ["closing balance", "statement period", "page", "statement end", "thank you"]
    private let boilerplatePatterns = [
        "hdfc bank",
        "contents of this statement",
        "no error is reported within",
        "account number",
        "account holder",
        "customer care",
        "statement generated on",
        "thank you for banking",
        "digital footprint",
        "mobile banking",
        "net banking",
        "cheque deposit",
        "financial inclusion",
        "cbdt annual returns",
        "ifsc code",
        "legal entity identifier",
        "pan",
        "aadhaar",
        "mca registered",
        "registered office",
        "bank guarantee",
        "state account branch",
        "joint holders",
        "od limit",
        "cust id",
        "virtual preferred",
        "statement summary",
        "requesting branch",
        "computer generated statement",
        "statement period",
        "closing balance",
        "phone no"
    ]

    func classify(_ line: String) -> ClassifiedLine {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            return ClassifiedLine(rawText: line, purpose: .blank, confidence: 1.0)
        }

        if isBoilerplate(trimmed) {
            return ClassifiedLine(rawText: line, purpose: .footer, confidence: 0.98)
        }

        if isHeader(trimmed) {
            return ClassifiedLine(rawText: line, purpose: .header, confidence: 1.0)
        }

        if isFooter(trimmed) {
            return ClassifiedLine(rawText: line, purpose: .footer, confidence: 0.95)
        }

        if let dateString = extractDate(trimmed) {
            return ClassifiedLine(rawText: line, purpose: .dateLine(dateString: dateString), confidence: 0.98)
        }

        if let balanceString = extractBalance(trimmed) {
            return ClassifiedLine(rawText: line, purpose: .balanceLine(balanceString: balanceString), confidence: 0.95)
        }

        let amounts = extractAmounts(trimmed)
        if !amounts.isEmpty {
            return ClassifiedLine(rawText: line, purpose: .amountLine(amounts: amounts), confidence: 0.92)
        }

        return ClassifiedLine(rawText: line, purpose: .narration, confidence: 0.70)
    }

    private func isBoilerplate(_ line: String) -> Bool {
        let lower = line.lowercased()
        return boilerplatePatterns.contains { lower.contains($0) }
    }

    private func isHeader(_ line: String) -> Bool {
        let lower = line.lowercased()
        let headerCount = headerKeywords.count(where: { lower.contains($0) })
        return headerCount >= 3
    }

    private func isFooter(_ line: String) -> Bool {
        let lower = line.lowercased()
        return footerKeywords.contains { lower.contains($0) }
    }

    private func extractDate(_ line: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: datePattern) else { return nil }
        let nsRange = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: nsRange),
              let range = Range(match.range, in: line)
        else { return nil }
        return String(line[range])
    }

    private func extractBalance(_ line: String) -> String? {
        let lower = line.lowercased()
        guard lower.contains("balance") else { return nil }

        guard let regex = try? NSRegularExpression(pattern: amountPattern) else { return nil }
        let nsRange = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: nsRange),
              let range = Range(match.range, in: line)
        else { return nil }
        return String(line[range])
    }

    private func extractAmounts(_ line: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: amountPattern) else { return [] }
        let nsRange = NSRange(line.startIndex..., in: line)
        let matches = regex.matches(in: line, range: nsRange)

        return matches.compactMap { match in
            guard let range = Range(match.range, in: line) else { return nil }
            return String(line[range])
        }
    }
}
