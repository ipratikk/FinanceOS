import FinanceCore
import Foundation
import Observation

@Observable
@MainActor
final class SheetViewModel: AsyncLoadable {
    private let bankRepository: any BankRepository
    private let ledgerRepository: any LedgerRepository

    private(set) var banks: [Bank] = []
    private(set) var accounts: [Ledger] = []
    var isLoading = false

    init(bankRepository: any BankRepository, ledgerRepository: any LedgerRepository) {
        self.bankRepository = bankRepository
        self.ledgerRepository = ledgerRepository
    }

    func load() async {
        await withLoading {
            async let banksFetch = bankRepository.fetchBanks()
            async let accountsFetch = ledgerRepository.fetchLedgers(kind: .bankAccount)
            banks = try await banksFetch
            accounts = try await accountsFetch
        }
    }
}
