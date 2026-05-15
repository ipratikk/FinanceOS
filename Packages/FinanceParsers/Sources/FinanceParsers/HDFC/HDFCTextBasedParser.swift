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
            if let debit = debit, let credit = credit {
                if debit > 0, credit == 0 {
                    amount = Int64(-debit * 100)
                } else if credit > 0, debit == 0 {
                    amount = Int64(credit * 100)
                } else {
                    amount = Int64((credit - debit) * 100)
                }
            } else if let credit = credit {
                amount = Int64(credit * 100)
            } else if let debit = debit {
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
        // Filter out large amounts (likely balances, not transactions)
        // Threshold: 5,000,000 paise = 50,000 INR (typical balance vs transaction)
        let filtered = amounts.filter { $0 < 500000 }

        guard !filtered.isEmpty else {
            return (nil, nil)
        }

        if filtered.count == 1 {
            // Single amount = credit
            return (nil, filtered[0])
        } else if filtered.count >= 2 {
            // Two+ amounts = debit, credit
            return (filtered[0], filtered[1])
        } else {
            return (nil, filtered.first)
        }
    }
}
