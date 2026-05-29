import FinanceParsers
import Foundation
import OSLog

/// Orchestrates the final stage of import: maps parsed transactions to domain models and persists them.
/// Sits between the parser layer and the repository — it owns no parsing and no SQL logic.
public struct TransactionImportPipeline: Sendable {
    private let repository: any TransactionWriter
    private let logger = FinanceLogger.importPipeline

    /// - Parameter repository: Write-only repository slice; keeps the pipeline decoupled from read concerns.
    public init(
        repository: any TransactionWriter
    ) {
        self.repository = repository
    }

    /// Maps all transactions in `statement` to domain `Transaction` values and persists them in one batch.
    /// - Returns: Counts of inserted vs. skipped (duplicate) rows for display in the import preview UI.
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
