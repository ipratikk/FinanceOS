import FinanceCore
import SwiftUI

struct SheetView: View {
    let route: SheetRoute
    let appContainer: AppContainer
    let navigator: AppNavigator
    @State private var viewModel: SheetViewModel

    init(route: SheetRoute, appContainer: AppContainer, navigator: AppNavigator) {
        self.route = route
        self.appContainer = appContainer
        self.navigator = navigator
        _viewModel = State(initialValue: SheetViewModel(
            bankRepository: appContainer.bankRepository,
            ledgerRepository: appContainer.ledgerRepository
        ))
    }

    var body: some View {
        Group {
            switch route {
            case let .accountEdit(ledger):
                CardEditView(
                    mode: .edit(ledger),
                    ledgerRepository: appContainer.ledgerRepository,
                    banks: viewModel.banks,
                    accounts: [],
                    onUpdate: navigator.accountReloadCallback
                )
            case let .cardEdit(ledger):
                CardEditView(
                    mode: .edit(ledger),
                    ledgerRepository: appContainer.ledgerRepository,
                    banks: viewModel.banks,
                    accounts: viewModel.accounts,
                    onUpdate: navigator.cardReloadCallback
                )
            case let .bankEdit(bank):
                let context = BankEditContext(
                    repository: appContainer.bankRepository,
                    ledgerRepository: appContainer.ledgerRepository
                )
                BankEditView(bank: bank, context: context)
            case let .transactionDetail(row):
                TransactionDetailView(row: row)
            default:
                EmptyView()
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
