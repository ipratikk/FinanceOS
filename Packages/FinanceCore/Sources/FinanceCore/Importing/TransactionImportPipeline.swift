import FinanceParsers
import Foundation
import OSLog

public struct TransactionImportPipeline: Sendable {
    private let repository: any TransactionWriter
    private let logger = FinanceLogger.importPipeline

    public init(
        repository: any TransactionWriter
    ) {
        self.repository = repository
    }

    public func execute(
        statement: ParsedStatement,
        target: TransactionImportTarget,
        ledgerKind: LedgerKind,
        context: OperationContext
    ) async throws -> ImportResult {
        let txnCount = statement.transactions.count

        logger.logDebug(
            "{op}: Mapping {count} txns for {kind}",
            [
                "op": context.name,
                "count": txnCount,
                "kind": ledgerKind.rawValue
            ]
        )

        let transactions = statement.transactions.map { parsedTxn in
            ParsedTransactionMapper.map(parsedTxn, target: target, ledgerKind: ledgerKind)
        }

        logger.logDebug(
            "{op}: Inserting mapped txns to repository",
            ["op": context.name]
        )

        let result = try await repository.insertTransactions(transactions)

        logger.logInfo(
            "{op}: Import complete - inserted: {inserted}, skipped: {skipped}",
            [
                "op": context.name,
                "inserted": result.inserted,
                "skipped": result.skipped
            ]
        )

        return result
    }
}
