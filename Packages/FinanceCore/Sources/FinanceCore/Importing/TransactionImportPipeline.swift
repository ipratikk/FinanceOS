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
        let parsed = try await importer.parseStatement(from: fileURL, format: format)

        let transactions = parsed.transactions.map { parsedTxn in
            let accountID: UUID?
            let cardID: UUID?

            switch target {
            case let .account(id):
                accountID = id
                cardID = nil
            case let .card(id):
                accountID = nil
                cardID = id
            }

            return Transaction(
                accountID: accountID,
                cardID: cardID,
                postedAt: parsedTxn.postedAt,
                description: parsedTxn.description,
                amountMinorUnits: abs(parsedTxn.amountMinorUnits),
                currencyCode: parsedTxn.currencyCode,
                transactionType: parsedTxn.amountMinorUnits < 0 ? .debit : .credit,
                sourceFingerprint: parsedTxn.sourceFingerprint
            )
        }

        return try await repository.insertTransactions(transactions)
    }
}
