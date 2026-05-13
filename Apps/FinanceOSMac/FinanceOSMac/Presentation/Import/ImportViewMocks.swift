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

    func insertTransactions(_ transactions: [FinanceCore.Transaction]) async throws {}
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
