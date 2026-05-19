import FinanceCore
import SwiftUI

@Observable
@MainActor
final class CardEditContext {
    let ledgerRepository: any LedgerRepository
    let banks: [Bank]
    let accounts: [Ledger]
    var deleteError: String?
    let onUpdate: (() async -> Void)?

    init(
        repository: any LedgerRepository,
        banks: [Bank],
        accounts: [Ledger],
        onUpdate: (() async -> Void)? = nil
    ) {
        ledgerRepository = repository
        self.banks = banks
        self.accounts = accounts
        self.onUpdate = onUpdate
    }

    func updateCard(_ ledger: Ledger) async {
        do {
            try await ledgerRepository.update(ledger)
            deleteError = nil
            await onUpdate?()
        } catch {
            deleteError = error.localizedDescription
        }
    }

    func deleteCard(id: UUID) async {
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
