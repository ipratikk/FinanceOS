import FinanceCore
import Foundation

struct MockTransactionRepository: TransactionRepository {
    func fetchTransactionsForAccount(_ accountID: UUID) async throws -> [FinanceCore.Transaction] {
        []
    }

    func fetchTransactionsForCard(_ cardID: UUID) async throws -> [FinanceCore.Transaction] {
        []
    }

    func fetchTransactions() async throws -> [FinanceCore.Transaction] {
        []
    }

    func insertTransactions(_ transactions: [FinanceCore.Transaction]) async throws -> ImportResult {
        ImportResult(inserted: transactions.count, skipped: 0)
    }
}

struct MockAccountRepository: AccountRepository {
    func fetchAccounts() async throws -> [Account] {
        []
    }
}

struct MockCardRepository: CardRepository {
    func fetchCards() async throws -> [Card] {
        []
    }
}

struct MockTransactionImporter: TransactionImporting {
    func parseStatement(from fileURL: URL, format: StatementFileFormat) async throws -> ParsedStatement {
        ParsedStatement(institution: "Mock", accountName: "Mock Account", transactions: [])
    }

    func importTransactions(
        from fileURL: URL,
        format: StatementFileFormat,
        target: TransactionImportTarget
    ) async throws -> [Transaction] {
        []
    }
}
