import FinanceCore
import FinanceParsers
import Foundation

struct MockTransactionRepository: TransactionRepository {
    func fetchTransactionsForLedger(_ ledgerID: UUID) async throws -> [FinanceCore.Transaction] {
        []
    }

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

    func delete(id: UUID) async throws {}

    func migrateTransactions(fromCard cardID: UUID, toAccount accountID: UUID) async throws {}

    func migrateTransactions(fromAccount accountID: UUID, toCard cardID: UUID) async throws {}

    func updateIntelligence(id: UUID, categoryId: String?, merchantName: String?) async throws {}

    func updateEnrichmentProvenance(id: UUID, _ provenance: EnrichmentProvenance) async throws {}

    func markUserCorrectedMerchant(id: UUID) async throws {}
}

struct MockBankRepository: BankRepository {
    func fetchBanks() async throws -> [Bank] {
        []
    }

    func insert(_ bank: Bank) async throws {}

    func update(_ bank: Bank) async throws {}

    func delete(id: UUID) async throws {}

    func deleteAll() async throws {}
}

struct MockLedgerRepository: LedgerRepository {
    func updateOpeningBalance(id: UUID, balance: Int64) async throws {
        ()
    }

    func fetchLedgers() async throws -> [Ledger] {
        []
    }

    func fetchLedgers(bankId: UUID) async throws -> [Ledger] {
        []
    }

    func fetchLedgers(kind: LedgerKind) async throws -> [Ledger] {
        []
    }

    func fetchLedgers(bankId: UUID, kind: LedgerKind) async throws -> [Ledger] {
        []
    }

    func fetchLedger(id: UUID) async throws -> Ledger? {
        nil
    }

    func insert(_ ledger: Ledger) async throws {}

    func update(_ ledger: Ledger) async throws {}

    func updateClosingBalance(id: UUID, balance: Int64, asOf: Date) async throws {}

    func archive(id: UUID) async throws {}

    func delete(id: UUID) async throws {}
}
