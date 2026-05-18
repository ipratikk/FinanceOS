import FinanceCore
import SwiftUI

struct AccountTransactionsDestinationView: View {
    let ledgerId: UUID
    let transactionRepository: any TransactionRepository
    let ledgerRepository: any LedgerRepository
    let bankRepository: any BankRepository

    @State private var ledger: Ledger?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let ledger {
                AccountTransactionsView(
                    ledger: ledger,
                    viewModel: AccountTransactionsViewModel(
                        transactionRepository: transactionRepository,
                        ledgerRepository: ledgerRepository,
                        bankRepository: bankRepository
                    )
                )
                .navigationTitle(ledger.displayName)
            } else if !isLoading {
                Text("Account not found")
            } else {
                ProgressView()
            }
        }
        .task {
            await loadLedger()
        }
    }

    private func loadLedger() async {
        do {
            let ledgers = try await ledgerRepository.fetchLedgers()
            ledger = ledgers.first(where: { $0.id == ledgerId })
        } catch {
            FinanceLogger.ui.logError(
                "Error loading ledger: {error}",
                caughtError: error,
                ["error": error.localizedDescription]
            )
        }
        isLoading = false
    }
}

struct CardTransactionsDestinationView: View {
    let ledgerId: UUID
    let transactionRepository: any TransactionRepository
    let ledgerRepository: any LedgerRepository

    @State private var ledger: Ledger?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let ledger {
                CardTransactionsView(
                    ledger: ledger,
                    viewModel: CardTransactionsViewModel(
                        transactionRepository: transactionRepository
                    )
                )
                .navigationTitle(ledger.displayName)
            } else if !isLoading {
                Text("Card not found")
            } else {
                ProgressView()
            }
        }
        .task {
            await loadLedger()
        }
    }

    private func loadLedger() async {
        do {
            let ledgers = try await ledgerRepository.fetchLedgers()
            ledger = ledgers.first(where: { $0.id == ledgerId })
        } catch {
            FinanceLogger.ui.logError(
                "Error loading ledger: {error}",
                caughtError: error,
                ["error": error.localizedDescription]
            )
        }
        isLoading = false
    }
}
