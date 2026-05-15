//
//  DefaultTransactionImporter.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import FinanceParsers

public struct DefaultTransactionImporter:
    TransactionImporting,
    Sendable
{
    private let delegate: FinanceParsers.DefaultTransactionImporter

    public init(
        parsers: [any StatementParser]? = nil,
        registry: StatementParserRegistry? = nil
    ) {
        delegate = FinanceParsers.DefaultTransactionImporter(parsers: parsers, registry: nil)
        _ = registry
    }

    public func parseStatement(
        from fileURL: URL,
        format: StatementFileFormat
    ) async throws -> ParsedStatement {
        return try await delegate.parseStatement(from: fileURL, format: format)
    }

    public func importTransactions(
        from fileURL: URL,
        format: StatementFileFormat,
        target: TransactionImportTarget
    ) async throws -> [Transaction] {
        let statement = try await parseStatement(
            from: fileURL,
            format: format
        )

        return statement.transactions.map { parsedTransaction in
            let transactionType: TransactionType = parsedTransaction.amountMinorUnits >= 0 ? .credit : .debit
            let absoluteAmount = abs(parsedTransaction.amountMinorUnits)

            switch target {
            case let .account(accountID):
                return Transaction(
                    accountID: accountID,
                    postedAt: parsedTransaction.postedAt,
                    description: parsedTransaction.description,
                    amountMinorUnits: absoluteAmount,
                    currencyCode: parsedTransaction.currencyCode,
                    transactionType: transactionType,
                    sourceFingerprint: parsedTransaction.sourceFingerprint
                )

            case let .card(cardID):
                return Transaction(
                    cardID: cardID,
                    postedAt: parsedTransaction.postedAt,
                    description: parsedTransaction.description,
                    amountMinorUnits: absoluteAmount,
                    currencyCode: parsedTransaction.currencyCode,
                    transactionType: transactionType,
                    sourceFingerprint: parsedTransaction.sourceFingerprint
                )
            }
        }
    }
}
