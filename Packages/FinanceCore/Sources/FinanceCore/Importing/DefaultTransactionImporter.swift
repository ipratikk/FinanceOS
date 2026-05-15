//
//  DefaultTransactionImporter.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceParsers
import Foundation

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
        do {
            return try await delegate.parseStatement(from: fileURL, format: format)
        } catch let e as FinanceParsers.TransactionImportError {
            throw e.asCoreError()
        }
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

private extension FinanceParsers.TransactionImportError {
    func asCoreError() -> TransactionImportError {
        switch self {
        case let .unsupportedFormat(s):
            return .unsupportedFormat(StatementFileFormat(rawValue: s) ?? .csv)
        case let .missingRequiredColumn(s):
            return .missingRequiredColumn(s)
        case let .invalidDate(s):
            return .invalidDate(s)
        case let .invalidAmount(s):
            return .invalidAmount(s)
        case let .malformedFile(s):
            return .malformedFile(s)
        case let .platformUnavailable(s):
            return .platformUnavailable(s)
        case let .passwordProtected(s):
            return .passwordProtected(s)
        }
    }
}
