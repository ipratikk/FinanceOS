import FinanceParsers
import Foundation

public struct TransactionImportPipeline: Sendable {
    private let repository: any TransactionRepository

    public init(
        repository: any TransactionRepository
    ) {
        self.repository = repository
    }

    public func execute(
        statement: ParsedStatement,
        target: TransactionImportTarget
    ) async throws -> ImportResult {
        let transactions = statement.transactions.map { parsedTxn in
            ParsedTransactionMapper.map(parsedTxn, target: target)
        }

        return try await repository.insertTransactions(transactions)
    }
}
