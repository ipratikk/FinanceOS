import FinanceCore
import Foundation
import Observation

@Observable
@MainActor
final class AccountTransactionsDestinationViewModel: AsyncLoadable {
    private let ledgerId: UUID
    private let ledgerRepository: any LedgerRepository

    private(set) var ledger: Ledger?
    var isLoading = false

    init(ledgerId: UUID, ledgerRepository: any LedgerRepository) {
        self.ledgerId = ledgerId
        self.ledgerRepository = ledgerRepository
    }

    func load() async {
        await withLoading {
            let ledgers = try await ledgerRepository.fetchLedgers()
            ledger = ledgers.first(where: { $0.id == ledgerId })
        }
    }
}
