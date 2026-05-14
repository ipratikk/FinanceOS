import FinanceCore
import SwiftUI

struct AccountTransactionsView: View {
    let account: Account
    @State private var viewModel: AccountTransactionsViewModel

    init(
        account: Account,
        viewModel: AccountTransactionsViewModel
    ) {
        self.account = account
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        TransactionListContentView(
            sections: viewModel.sections,
            listState: viewModel.listState
        )
        .task {
            await viewModel.loadTransactions(for: account.id)
        }
    }
}
