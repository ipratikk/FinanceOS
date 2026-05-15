import Foundation

class HDFCTextBasedParser {
    private let datePattern = try! NSRegularExpression(pattern: "^\\s*\\d{2}/\\d{2}/\\d{2}")
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yy"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "Asia/Kolkata")
        return df
    }()

    struct ReconstructedTransaction {
        let date: String
        let narrationLines: [String]
        let amounts: [Double]
    }

    func reconstructTransactions(from lines: [String]) -> [ReconstructedTransaction] {
        var transactions: [ReconstructedTransaction] = []
        var currentDate: String?
        var currentNarration: [String] = []
        var currentAmounts: [Double] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                continue
            }

            // Check if line starts with date
            if let date = extractDate(from: trimmed) {
                // Save previous transaction if exists
                if let date = currentDate {
                    transactions.append(ReconstructedTransaction(
                        date: date,
                        narrationLines: currentNarration,
                        amounts: currentAmounts
                    ))
                }

                // Start new transaction
                currentDate = date
                currentNarration = []
                currentAmounts = []

                // Extract amounts from this line
                currentAmounts = extractAmounts(from: trimmed)
            } else {
                // Continuation of narration for current transaction
                if currentDate != nil {
                    currentNarration.append(trimmed)

                    // Extract amounts from narration continuation
                    currentAmounts.append(contentsOf: extractAmounts(from: trimmed))
                }
            }
        }

        // Don't forget last transaction
        if let date = currentDate {
            transactions.append(ReconstructedTransaction(
                date: date,
                narrationLines: currentNarration,
                amounts: currentAmounts
            ))
        }

        return transactions
    }

    func parseToNormalizedTransactions(_ reconstructed: [ReconstructedTransaction]) -> [ParsedTransaction] {
        var transactions: [ParsedTransaction] = []

        for txn in reconstructed {
            let narration = txn.narrationLines.joined(separator: " ").trimmingCharacters(in: .whitespaces)

            // Determine debit/credit from amounts
            let (debit, credit) = extractDebitCredit(from: txn.amounts)

            guard debit != nil || credit != nil else {
                continue
            }

            // Calculate amount
            let amount: Int64
            if let debit, let credit {
                if debit > 0, credit == 0 {
                    amount = Int64(-debit * 100)
                } else if credit > 0, debit == 0 {
                    amount = Int64(credit * 100)
                } else {
                    amount = Int64((credit - debit) * 100)
                }
            } else if let credit {
                amount = Int64(credit * 100)
            } else if let debit {
                amount = Int64(-debit * 100)
            } else {
                continue
            }

            guard let postedAt = dateFormatter.date(from: txn.date) else {
                continue
            }

            let transaction = ParsedTransaction(
                postedAt: postedAt,
                description: narration,
                amountMinorUnits: amount,
                currencyCode: "INR",
                sourceFingerprint: "\(txn.date)|\(narration)|\(amount)"
            )
            transactions.append(transaction)
        }

        return transactions
    }

    // MARK: - Helpers

    private func extractDate(from line: String) -> String? {
        let nsRange = NSRange(line.startIndex..., in: line)
        guard let match = datePattern.firstMatch(in: line, range: nsRange),
              let range = Range(match.range, in: line)
        else {
            return nil
        }
        return String(line[range]).trimmingCharacters(in: .whitespaces)
    }

    private func extractAmounts(from line: String) -> [Double] {
        var amounts: [Double] = []

        let parts = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        for part in parts {
            if let amount = parseAmount(part) {
                amounts.append(amount)
            }
        }

        return amounts
    }

    private func parseAmount(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }

    private func extractDebitCredit(from amounts: [Double]) -> (debit: Double?, credit: Double?) {
        // HDFC format: [withdrawal_amt, deposit_amt, closing_balance, ...]
        // Only use the first 3 amounts; ignore any beyond (they're from narration)
        let significantAmounts = amounts.prefix(3)

        guard significantAmounts.count >= 2 else {
            return (nil, nil)
        }

        let withdrawal = significantAmounts[0]
        let deposit = significantAmounts[1]
        // closing_balance (significantAmounts[2]) is ignored

        // In HDFC format, withdrawal and deposit are mutually exclusive
        let debit = withdrawal > 0 ? withdrawal : nil
        let credit = deposit > 0 ? deposit : nil

        return (debit, credit)
    }
}
