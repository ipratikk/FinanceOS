import Foundation

class HDFCTransactionParser {
    private let dateFormatters: [DateFormatter] = {
        let formats = ["dd/MM/yy", "dd/MM/yyyy"]
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            return formatter
        }
    }()

    func parseTransactionBlock(_ block: TransactionBlock) -> HDFCRawTransaction? {
        guard let dateLineIndex = block.dateLineIndex else { return nil }
        guard dateLineIndex < block.lines.count else { return nil }

        let dateLineRaw = block.lines[dateLineIndex].rawText
        guard let dateString = extractDateString(from: dateLineRaw) else { return nil }

        let narration = block.narrationLines
            .map { $0.rawText.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard let (debit, credit) = extractDebitCredit(from: block) else { return nil }

        let confidence = calculateConfidence(
            dateConfidence: 0.98,
            amountConfidence: 0.85,
            descriptionConfidence: narration.isEmpty ? 0.5 : 0.80
        )

        return HDFCRawTransaction(
            dateString: dateString,
            description: narration,
            debitAmount: debit,
            creditAmount: credit,
            balance: nil,
            confidence: confidence,
            warnings: [],
            sourceLineIndices: block.lines.enumerated().map(\.offset)
        )
    }

    private func extractDateString(from line: String) -> String? {
        let pattern = "\\d{2}/\\d{2}/\\d{2}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsRange = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: nsRange),
              let range = Range(match.range, in: line)
        else { return nil }
        return String(line[range])
    }

    private func extractDebitCredit(from block: TransactionBlock) -> (debit: String?, credit: String?)? {
        var allAmounts: [String] = []

        for amountLineIndex in block.amountLineIndices {
            guard amountLineIndex < block.lines.count else { continue }
            let line = block.lines[amountLineIndex]

            if case let .amountLine(amounts: amounts) = line.purpose {
                allAmounts.append(contentsOf: amounts)
            }
        }

        guard allAmounts.count >= 1 else { return nil }

        if allAmounts.count == 1 {
            return (nil, allAmounts[0])
        }

        if allAmounts.count == 2 {
            let debitValue = parseAmount(allAmounts[0])
            let creditValue = parseAmount(allAmounts[1])
            if debitValue == 0, creditValue > 0 {
                return (nil, allAmounts[1])
            }
            if creditValue == 0, debitValue > 0 {
                return (allAmounts[0], nil)
            }
            return (allAmounts[0], allAmounts[1])
        }

        var validAmounts = allAmounts.filter { !isLikelyBalance($0) }
        if validAmounts.isEmpty { validAmounts = allAmounts }

        if validAmounts.count >= 2 {
            let debit = validAmounts[validAmounts.count - 2]
            let credit = validAmounts[validAmounts.count - 1]
            let debitValue = parseAmount(debit)
            let creditValue = parseAmount(credit)

            if debitValue == 0, creditValue > 0 {
                return (nil, credit)
            }
            if creditValue == 0, debitValue > 0 {
                return (debit, nil)
            }
            return (debit, credit)
        }

        if validAmounts.count == 1 {
            return (nil, validAmounts[0])
        }

        return nil
    }

    private func isLikelyBalance(_ amountString: String) -> Bool {
        let value = parseAmount(amountString)
        return value > 50_000_000
    }

    private func parseAmount(_ amountString: String) -> Int64 {
        let cleaned = amountString
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let decimal = Decimal(string: cleaned) else { return 0 }
        let minorUnits = decimal * 100
        let rounded = NSDecimalNumber(decimal: minorUnits).rounding(accordingToBehavior: nil)
        return rounded.int64Value
    }

    func validateDate(_ dateString: String) -> Date? {
        for formatter in dateFormatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }

    private func calculateConfidence(
        dateConfidence: Double,
        amountConfidence: Double,
        descriptionConfidence: Double
    ) -> TransactionConfidence {
        TransactionConfidence(
            dateConfidence: dateConfidence,
            amountConfidence: amountConfidence,
            descriptionConfidence: descriptionConfidence
        )
    }
}
