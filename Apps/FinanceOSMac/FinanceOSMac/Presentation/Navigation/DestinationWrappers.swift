import FinanceCore
import FinanceUI
import SwiftUI

struct AccountTransactionsDestinationView: View {
    let transactionRepository: any TransactionRepository
    let ledgerRepository: any LedgerRepository
    let bankRepository: any BankRepository
    @State private var viewModel: AccountTransactionsDestinationViewModel

    init(
        ledgerId: UUID,
        transactionRepository: any TransactionRepository,
        ledgerRepository: any LedgerRepository,
        bankRepository: any BankRepository
    ) {
        self.transactionRepository = transactionRepository
        self.ledgerRepository = ledgerRepository
        self.bankRepository = bankRepository
        _viewModel = State(initialValue: AccountTransactionsDestinationViewModel(
            ledgerId: ledgerId,
            ledgerRepository: ledgerRepository
        ))
    }

    var body: some View {
        Group {
            if let ledger = viewModel.ledger {
                AccountTransactionsView(
                    ledger: ledger,
                    viewModel: AccountTransactionsViewModel(
                        transactionRepository: transactionRepository,
                        ledgerRepository: ledgerRepository,
                        bankRepository: bankRepository
                    )
                )
                .navigationTitle(ledger.displayName)
            } else if !viewModel.isLoading {
                FDSLabel("Account not found")
            } else {
                ProgressView()
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

struct CardTransactionsDestinationView: View {
    let transactionRepository: any TransactionRepository
    let ledgerRepository: any LedgerRepository
    @State private var viewModel: CardTransactionsDestinationViewModel

    init(
        ledgerId: UUID,
        transactionRepository: any TransactionRepository,
        ledgerRepository: any LedgerRepository
    ) {
        self.transactionRepository = transactionRepository
        self.ledgerRepository = ledgerRepository
        _viewModel = State(initialValue: CardTransactionsDestinationViewModel(
            ledgerId: ledgerId,
            ledgerRepository: ledgerRepository
        ))
    }

    var body: some View {
        Group {
            if let ledger = viewModel.ledger {
                CardTransactionsView(
                    ledger: ledger,
                    viewModel: CardTransactionsViewModel(
                        transactionRepository: transactionRepository
                    )
                )
                .navigationTitle(ledger.displayName)
            } else if !viewModel.isLoading {
                FDSLabel("Card not found")
            } else {
                ProgressView()
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

struct LedgerDetailDestinationView: View {
    @State private var viewModel: LedgerDetailViewModel

    init(ledgerId: UUID) {
        let container = AppContainer.shared
        _viewModel = State(initialValue: LedgerDetailViewModel(
            ledgerId: ledgerId,
            ledgerRepository: container.ledgerRepository,
            bankRepository: container.bankRepository
        ))
    }

    var body: some View {
        LedgerDetailView(viewModel: viewModel)
    }
}
