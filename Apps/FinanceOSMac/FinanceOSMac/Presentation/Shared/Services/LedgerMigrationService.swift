import FinanceCore
import Foundation

protocol LedgerMigrationProtocol: Sendable {
    func convertToAccount(_ card: Ledger) async throws
    func convertToCard(_ account: Ledger) async throws
}

final class LedgerMigrationService: LedgerMigrationProtocol {
    private let ledgerRepository: any LedgerRepository
    private let transactionRepository: any TransactionRepository

    init(ledgerRepository: any LedgerRepository, transactionRepository: any TransactionRepository) {
        self.ledgerRepository = ledgerRepository
        self.transactionRepository = transactionRepository
    }

    func convertToAccount(_ card: Ledger) async throws {
        let account = Ledger(
            id: UUID(),
            bankId: card.bankId,
            kind: .bankAccount,
            displayName: card.displayName,
            last4: card.last4
        )
        try await ledgerRepository.insert(account)
        try await transactionRepository.migrateTransactions(fromCard: card.id, toAccount: account.id)
        try await ledgerRepository.delete(id: card.id)
    }

    func convertToCard(_ account: Ledger) async throws {
        let card = Ledger(
            id: UUID(),
            bankId: account.bankId,
            kind: .creditCard,
            displayName: account.displayName,
            last4: account.last4,
            linkedLedgerId: account.id
        )
        try await ledgerRepository.insert(card)
        try await transactionRepository.migrateTransactions(fromAccount: account.id, toCard: card.id)
        try await ledgerRepository.delete(id: account.id)
    }
}
