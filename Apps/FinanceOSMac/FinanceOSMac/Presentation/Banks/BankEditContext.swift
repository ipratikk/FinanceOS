import FinanceCore
import SwiftUI

@Observable
@MainActor
final class BankEditContext {
    let repository: any BankRepository
    let ledgerRepository: any LedgerRepository
    var linkedLedgers: [Ledger] = []
    var error: String?

    init(repository: any BankRepository, ledgerRepository: any LedgerRepository) {
        self.repository = repository
        self.ledgerRepository = ledgerRepository
    }

    func loadLedgers(bankId: UUID) async {
        do {
            linkedLedgers = try await ledgerRepository.fetchLedgers(bankId: bankId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateBank(_ bank: Bank) async {
        do {
            try await repository.update(bank)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteBank(id: UUID) async {
        do {
            try await repository.delete(id: id)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func clearError() {
        error = nil
    }
}
