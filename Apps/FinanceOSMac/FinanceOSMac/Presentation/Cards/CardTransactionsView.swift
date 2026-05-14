import FinanceCore
import SwiftUI

struct CardTransactionsView: View {
    let card: Card
    @State private var viewModel: CardTransactionsViewModel

    init(
        card: Card,
        viewModel: CardTransactionsViewModel
    ) {
        self.card = card
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        TransactionListContentView(
            sections: viewModel.sections,
            listState: viewModel.listState
        )
        .task {
            await viewModel.loadTransactions(for: card.id)
        }
    }
}
