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
        return block.narrationLines
            .map { line in
                return line.rawText.trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
