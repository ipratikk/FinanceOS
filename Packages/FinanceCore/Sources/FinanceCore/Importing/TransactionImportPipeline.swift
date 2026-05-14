import Foundation

public struct TransactionImportPipeline: Sendable {
    private let importer: any TransactionImporting
    private let repository: any TransactionRepository

    public init(
        importer: any TransactionImporting,
        repository: any TransactionRepository
    ) {
        self.importer = importer
        self.repository = repository
    }

    public func execute(
        fileURL: URL,
        format: StatementFileFormat,
        target: TransactionImportTarget
    ) async throws -> ImportResult {
        let parsed = try importer.importTransactions(from: fileURL, format: format)

        let transactions = parsed.transactions.map { parsedTxn in
            Transaction(
                postedAt: parsedTxn.postedAt,
                description: parsedTxn.description,
                amountMinorUnits: parsedTxn.amountMinorUnits,
                currencyCode: parsedTxn.currencyCode,
                transactionType: parsedTxn.amountMinorUnits < 0 ? .debit : .credit,
                sourceFingerprint: parsedTxn.sourceFingerprint,
                accountID: target.accountID,
                cardID: target.cardID
            )
        }

        return try await repository.insertTransactions(transactions)
    }
}
