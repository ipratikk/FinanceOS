import FinanceCore
import SwiftUI

@Observable
@MainActor
final class AccountEditContext {
    let ledgerRepository: any LedgerRepository
    let banks: [Bank]
    var deleteError: String?

    init(repository: any LedgerRepository, banks: [Bank]) {
        ledgerRepository = repository
        self.banks = banks
    }

    func updateAccount(_ ledger: Ledger) async {
        do {
            try await ledgerRepository.update(ledger)
            deleteError = nil
        } catch {
            deleteError = error.localizedDescription
        }
    }

    func deleteAccount(id: UUID) async {
        do {
            try await ledgerRepository.delete(id: id)
            deleteError = nil
        } catch {
            deleteError = error.localizedDescription
        }
    }

    func clearError() {
        deleteError = nil
    }
}
