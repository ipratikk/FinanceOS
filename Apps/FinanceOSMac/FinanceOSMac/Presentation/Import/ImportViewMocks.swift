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

    func migrateTransactions(fromCard cardID: UUID, toAccount accountID: UUID) async throws {}

    func migrateTransactions(fromAccount accountID: UUID, toCard cardID: UUID) async throws {}
}

struct MockInstitutionRepository: InstitutionRepository {
    func fetchInstitutions() async throws -> [Institution] {
        []
    }

    func insert(_ institution: Institution) async throws {}

    func update(_ institution: Institution) async throws {}

    func delete(id: UUID) async throws {}
}

struct MockAccountRepository: AccountRepository {
    func fetchAccounts() async throws -> [Account] {
        []
    }

    func insert(_ account: Account) async throws {}

    func update(_ account: Account) async throws {}

    func delete(id: UUID) async throws {}
}

struct MockCardRepository: CardRepository {
    func fetchCards() async throws -> [Card] {
        []
    }

    func insert(_ card: Card) async throws {}

    func update(_ card: Card) async throws {}

    func delete(id: UUID) async throws {}
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
