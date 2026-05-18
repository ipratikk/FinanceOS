import FinanceCore
import SwiftUI

@Observable
@MainActor
final class AccountEditContext {
    let ledgerRepository: any LedgerRepository
    let banks: [Bank]
    let onUpdate: (() async -> Void)?
    var deleteError: String?

    init(repository: any LedgerRepository, banks: [Bank], onUpdate: (() async -> Void)? = nil) {
        ledgerRepository = repository
        self.banks = banks
        self.onUpdate = onUpdate
    }

    func updateAccount(_ ledger: Ledger) async {
        do {
            try await ledgerRepository.update(ledger)
            deleteError = nil
            await onUpdate?()
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
