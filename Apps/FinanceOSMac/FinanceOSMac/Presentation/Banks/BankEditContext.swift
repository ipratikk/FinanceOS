import FinanceCore
import SwiftUI

@Observable
@MainActor
final class BankEditContext {
    let repository: any BankRepository
    var deleteError: String?

    init(repository: any BankRepository) {
        self.repository = repository
    }

    func updateBank(_ bank: Bank) async {
        do {
            try await repository.update(bank)
            deleteError = nil
        } catch {
            deleteError = error.localizedDescription
        }
    }

    func deleteBank(id: UUID) async {
        do {
            try await repository.delete(id: id)
            deleteError = nil
        } catch {
            deleteError = error.localizedDescription
        }
    }

    func clearError() {
        deleteError = nil
    }
}
