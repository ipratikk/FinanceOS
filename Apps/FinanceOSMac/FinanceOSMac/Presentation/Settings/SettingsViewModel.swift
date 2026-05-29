import FinanceCore
import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    private let bankRepository: any BankRepository

    var errorMessage: String?

    init(bankRepository: any BankRepository) {
        self.bankRepository = bankRepository
    }

    func clearAllData() async {
        do {
            try await bankRepository.deleteAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
