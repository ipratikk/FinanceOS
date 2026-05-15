//
//  HDFCBalanceValidator.swift
//  FinanceCore
//
//  Created by Pratik Goel on 15/05/26.
//

import Foundation

class HDFCBalanceValidator {
    func validateTransactions(
        _ transactions: [ParsedTransaction],
        startingBalance: Int64? = nil
    ) -> ValidationResult {
        guard !transactions.isEmpty else {
            return ValidationResult(
                isValid: true,
                discrepancies: [],
                recoveryAttempted: false,
                recoveredTransactionCount: 0
            )
        }

        var discrepancies: [BalanceDiscrepancy] = []
        var currentBalance = startingBalance ?? 0

        for (index, txn) in transactions.enumerated() {
            currentBalance += txn.amountMinorUnits

            guard let expectedBalance = extractBalanceFromDescription(txn.description) else {
                continue
            }

            let difference = abs(currentBalance - expectedBalance)
            if difference > 0 {
                discrepancies.append(
                    BalanceDiscrepancy(
                        expectedBalance: expectedBalance,
                        calculatedBalance: currentBalance,
                        transactionIndex: index,
                        difference: difference
                    )
                )
            }
        }

        let isValid = discrepancies.isEmpty
        return ValidationResult(
            isValid: isValid,
            discrepancies: discrepancies,
            recoveryAttempted: false,
            recoveredTransactionCount: 0
        )
    }

    private func extractBalanceFromDescription(_ description: String) -> Int64? {
        let balancePattern = "Balance[:\\s]*([\\d,]+\\.\\d{2})"
        guard let regex = try? NSRegularExpression(pattern: balancePattern, options: .caseInsensitive) else {
            return nil
        }

        let nsRange = NSRange(description.startIndex..., in: description)
        guard let match = regex.firstMatch(in: description, range: nsRange),
              let range = Range(match.range(at: 1), in: description)
        else { return nil }

        let balanceStr = String(description[range])
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let decimal = Decimal(string: balanceStr) else { return nil }
        let minorUnits = decimal * 100
        let rounded = NSDecimalNumber(decimal: minorUnits).rounding(accordingToBehavior: nil)
        return rounded.int64Value
    }
}
