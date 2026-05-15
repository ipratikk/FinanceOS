//
//  HDFCErrorRecovery.swift
//  FinanceCore
//
//  Created by Pratik Goel on 15/05/26.
//

import Foundation

class HDFCErrorRecovery {
    func salvagePartialTransaction(
        from block: TransactionBlock,
        parser: HDFCTransactionParser
    ) -> HDFCRawTransaction? {
        guard let dateLineIndex = block.dateLineIndex else { return nil }
        guard dateLineIndex < block.lines.count else { return nil }

        let dateLineRaw = block.lines[dateLineIndex].rawText
        guard let dateString = extractDateString(from: dateLineRaw) else { return nil }

        let narration = block.narrationLines
            .map { $0.rawText.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let (debit, credit) = extractAnyAmount(from: block)

        let confidence = calculateLowConfidence(
            hasDate: true,
            hasAmount: debit != nil || credit != nil,
            hasNarration: !narration.isEmpty
        )

        let warnings: [ParseWarning] = []
        var allWarnings = warnings

        if debit == nil, credit == nil {
            allWarnings.append(
                ParseWarning(
                    category: "amount",
                    message: "No valid amounts found; transaction may be incomplete",
                    lineNumber: dateLineIndex
                )
            )
        }

        if narration.isEmpty {
            allWarnings.append(
                ParseWarning(
                    category: "narration",
                    message: "No transaction description available",
                    lineNumber: dateLineIndex
                )
            )
        }

        return HDFCRawTransaction(
            dateString: dateString,
            description: narration,
            debitAmount: debit,
            creditAmount: credit,
            balance: nil,
            confidence: confidence,
            warnings: allWarnings,
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

    private func extractAnyAmount(from block: TransactionBlock) -> (debit: String?, credit: String?) {
        var allAmounts: [String] = []

        for amountLineIndex in block.amountLineIndices {
            guard amountLineIndex < block.lines.count else { continue }
            let line = block.lines[amountLineIndex]

            if case let .amountLine(amounts: amounts) = line.purpose {
                allAmounts.append(contentsOf: amounts)
            }
        }

        guard !allAmounts.isEmpty else { return (nil, nil) }

        if allAmounts.count >= 2 {
            return (allAmounts[allAmounts.count - 2], allAmounts[allAmounts.count - 1])
        }

        return (nil, allAmounts[0])
    }

    private func calculateLowConfidence(
        hasDate: Bool,
        hasAmount: Bool,
        hasNarration: Bool
    ) -> TransactionConfidence {
        let dateConfidence: Double = hasDate ? 0.90 : 0.0
        let amountConfidence: Double = hasAmount ? 0.60 : 0.0
        let descriptionConfidence: Double = hasNarration ? 0.50 : 0.0

        return TransactionConfidence(
            dateConfidence: dateConfidence,
            amountConfidence: amountConfidence,
            descriptionConfidence: descriptionConfidence
        )
    }
}
