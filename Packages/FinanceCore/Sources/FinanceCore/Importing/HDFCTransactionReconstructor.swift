//
//  HDFCTransactionReconstructor.swift
//  FinanceCore
//
//  Created by Pratik Goel on 15/05/26.
//

import Foundation

class HDFCTransactionReconstructor {
    func reconstructTransactionBlocks(from classifiedLines: [ClassifiedLine]) -> [TransactionBlock] {
        var blocks: [TransactionBlock] = []
        var currentBlock: TransactionBlock?

        for (index, line) in classifiedLines.enumerated() {
            switch line.purpose {
            case .dateLine:
                if let block = currentBlock, block.isComplete {
                    blocks.append(block)
                }
                currentBlock = TransactionBlock(lines: [line])
                currentBlock?.dateLineIndex = 0

            case .amountLine:
                if currentBlock == nil {
                    currentBlock = TransactionBlock(lines: [line])
                } else {
                    currentBlock?.lines.append(line)
                }
                if currentBlock != nil {
                    let lastIndex = currentBlock!.lines.count - 1
                    currentBlock!.amountLineIndices.append(lastIndex)
                }

            case .narration:
                if currentBlock == nil {
                    currentBlock = TransactionBlock(lines: [line])
                } else {
                    currentBlock?.lines.append(line)
                }
                currentBlock?.narrationLines.append(line)

            case .header, .footer, .blank, .unknown, .balanceLine:
                continue

            default:
                continue
            }
        }

        if let block = currentBlock, block.isComplete {
            blocks.append(block)
        }

        return blocks
    }

    func mergeFragmentedNarration(from block: TransactionBlock) -> String {
        let merged = block.narrationLines
            .map { line in
                return line.rawText.trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if merged.count > 500 {
            return truncateBoilerplateMerge(merged)
        }

        return merged
    }

    private func truncateBoilerplateMerge(_ text: String) -> String {
        let boilerplateKeywords = [
            "contents of this statement",
            "no error is reported within",
            "statement generated on",
            "thank you for banking",
            "digital footprint",
            "account number",
            "ifsc code"
        ]

        let lower = text.lowercased()
        for keyword in boilerplateKeywords {
            if let range = lower.range(of: keyword) {
                let endIndex = lower.index(range.lowerBound, offsetBy: 0)
                let truncated = String(text[..<endIndex]).trimmingCharacters(in: .whitespaces)
                if !truncated.isEmpty {
                    return truncated
                }
            }
        }

        let sentences = text.components(separatedBy: ".")
        if sentences.count > 1 {
            return (sentences.first ?? "").trimmingCharacters(in: .whitespaces)
        }

        return String(text.prefix(200)).trimmingCharacters(in: .whitespaces)
    }
}
