import FinanceCore
import FinanceUI
import Foundation
import Observation

@Observable
@MainActor
final class LedgerDetailViewModel: AsyncLoadable {
    private let ledgerId: UUID
    private let ledgerRepository: any LedgerRepository
    private let bankRepository: any BankRepository

    private(set) var ledger: Ledger?
    private(set) var bank: Bank?
    var isLoading = false

    init(ledgerId: UUID, ledgerRepository: any LedgerRepository, bankRepository: any BankRepository) {
        self.ledgerId = ledgerId
        self.ledgerRepository = ledgerRepository
        self.bankRepository = bankRepository
    }

    func load() async {
        await withLoading {
            ledger = try await ledgerRepository.fetchLedger(id: ledgerId)
            if let fetched = ledger {
                let banks = try await bankRepository.fetchBanks()
                bank = banks.first { $0.id == fetched.bankId }
            }
        }
    }

    var balanceText: String {
        FormatterCache.formatCurrency(minorUnits: ledger?.closingBalance ?? 0)
    }

    var navigationTitle: String {
        ledger?.displayName ?? "Ledger"
    }
}
