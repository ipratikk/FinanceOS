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
        let withdrawal: Double?
        let deposit: Double?
    }

    func reconstructTransactions(from lines: [String]) -> [ReconstructedTransaction] {
        var transactions: [ReconstructedTransaction] = []
        var currentDate: String?
        var currentNarration: [String] = []
        var currentAmounts: [Double] = []
        var currentWithdrawal: Double?
        var currentDeposit: Double?

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
                        amounts: currentAmounts,
                        withdrawal: currentWithdrawal,
                        deposit: currentDeposit
                    ))
                }

                // Start new transaction
                currentDate = date
                currentNarration = []
                currentAmounts = []
                currentWithdrawal = nil
                currentDeposit = nil

                // Extract amounts from this line
                currentAmounts = extractAmounts(from: trimmed)
            } else {
                // Continuation of narration for current transaction
                if currentDate != nil {
                    currentNarration.append(trimmed)
                    currentAmounts.append(contentsOf: extractAmounts(from: trimmed))
                }
            }
        }

        // Don't forget last transaction
        if let date = currentDate {
            transactions.append(ReconstructedTransaction(
                date: date,
                narrationLines: currentNarration,
                amounts: currentAmounts,
                withdrawal: currentWithdrawal,
                deposit: currentDeposit
            ))
        }

        return transactions
    }

    func parseToNormalizedTransactions(_ reconstructed: [ReconstructedTransaction]) -> [ParsedTransaction] {
        var transactions: [ParsedTransaction] = []

        for txn in reconstructed {
            let narration = txn.narrationLines.joined(separator: "\t").trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "\t", with: " ")

            // Determine debit/credit from amounts using heuristic
            let (debit, credit) = extractDebitCredit(from: txn.amounts)

            guard debit != nil || credit != nil else {
                continue
            }

            // Calculate amount
            let amount: Int64
            if let debit {
                amount = Int64(-debit * 100)
            } else if let credit {
                amount = Int64(credit * 100)
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

        // Split by tabs (column separator) and spaces (within column)
        let columns = line.split(separator: "\t", omittingEmptySubsequences: true).map(String.init)
        for column in columns {
            let parts = column.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            for part in parts {
                if let amount = parseAmount(part) {
                    amounts.append(amount)
                }
            }
        }

        return amounts
    }

    private func parseAmount(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
        guard let value = Double(cleaned) else { return nil }

        // Filter out likely dates (DDMMYY = 6 digits) and reference numbers
        if cleaned.count == 6, Int(cleaned) != nil {
            return nil
        }

        return value
    }

    private func extractDebitCredit(from amounts: [Double]) -> (debit: Double?, credit: Double?) {
        // HDFC format: Withdrawal Amt | Deposit Amt | Closing Balance
        // Challenge: Vision OCR extracts all amounts (including closing balance) without column info.
        // Strategy: Identify transaction amount by excluding balance.
        let txnAmounts = amounts.filter { $0 >= 100 && $0 < 1_000_000 }

        guard !txnAmounts.isEmpty else {
            return (nil, nil)
        }

        // If we have 2+ amounts, exclude the largest (likely closing balance)
        // and use the smaller amount(s) as transaction candidate(s).
        let amount: Double
        if txnAmounts.count >= 2 {
            let sorted = txnAmounts.sorted()
            // Check if there's a clear pair like [2500, 0] or [0, 8679]
            if sorted.count >= 2, sorted[0] == 0 || sorted[1] == 0 {
                // Prefer the non-zero amount as transaction
                amount = sorted.first(where: { $0 > 0 }) ?? sorted[0]
            } else {
                // Take median or second-smallest (exclude the largest balance)
                amount = sorted.count > 2 ? sorted[1] : sorted[0]
            }
        } else {
            amount = txnAmounts[0]
        }

        // Classify: most transactions are < 100K (payments), larger ones > 100K (deposits/salary)
        // This heuristic fails for large withdrawals, but works for most cases.
        let debit: Double?
        let credit: Double?

        if amount >= 100_000 {
            credit = amount
            debit = nil
        } else {
            debit = amount
            credit = nil
        }

        return (debit, credit)
    }
}
