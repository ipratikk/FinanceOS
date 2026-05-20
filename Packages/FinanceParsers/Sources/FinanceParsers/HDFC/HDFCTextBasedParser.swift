import Foundation

class HDFCTextBasedParser {
    private let datePattern: NSRegularExpression = {
        do {
            return try NSRegularExpression(pattern: "^\\s*\\d{2}/\\d{2}/\\d{2}")
        } catch {
            preconditionFailure("Invalid HDFC date regex: \(error)")
        }
    }()

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

            // Skip footer lines (metadata keywords or unusually long descriptions)
            let lower = narration.lowercased()
            if lower.contains("statement summary") || lower.contains("page no") ||
                lower.contains("contents of this statement") || lower.contains("hdfc bank limited") ||
                lower.contains("closing balance includes") || lower.contains("registered office") ||
                lower.contains("gstin") || lower.contains("nominated") ||
                lower.contains("we understand your world") || narration.count > 500 {
                continue
            }

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

        // Check if line uses tab-separated columns (from Vision column detection)
        let columns = line.split(separator: "\t", omittingEmptySubsequences: true).map(String.init)

        // If tab-separated, preserve column order for debit/credit detection
        if columns.count > 1 {
            for column in columns {
                let parts = column.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
                for part in parts {
                    if let amount = parseAmount(String(part)) {
                        amounts.append(amount)
                    }
                }
            }
        } else {
            // Fallback: split by spaces (non-tab format)
            let parts = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            for part in parts {
                if let amount = parseAmount(String(part)) {
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
        // HDFC format: Debit Amt | Credit Amt | Closing Balance
        // With Vision column detection, amounts are in column order:
        // [date_parts..., debit, credit, ref_number, closing_balance]
        // Heuristic: first two non-zero amounts in range 100-1M are debit/credit

        let filtered = amounts.filter { $0 >= 0 && $0 < 1_000_000 }
        guard filtered.count >= 2 else {
            return (nil, nil)
        }

        // Look for debit/credit pair: one is zero, one is non-zero in first few amounts
        for i in 0 ..< min(4, filtered.count - 1) {
            let amt0 = filtered[i]
            let amt1 = filtered[i + 1]

            // Check for [debit, 0] or [0, credit] pattern
            if amt0 > 100, amt0 < 1_000_000, amt1 == 0 {
                return (amt0, nil) // Debit only
            }
            if amt0 == 0, amt1 > 100, amt1 < 1_000_000 {
                return (nil, amt1) // Credit only
            }
        }

        // Fallback: pick smallest valid amount (usually transaction, not balance)
        let txnAmounts = filtered.filter { $0 >= 100 && $0 < 1_000_000 }
        guard let amount = txnAmounts.min() else {
            return (nil, nil)
        }

        if amount >= 100_000 {
            return (nil, amount)
        } else {
            return (amount, nil)
        }
    }
}
