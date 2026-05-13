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
        List(viewModel.transactionRows) { transactionRow in
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: transactionRow
                    .transactionType == .debit ? "arrow.up.left.circle.fill" : "arrow.down.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(transactionRow.transactionType == .debit ? .red : .green)

                VStack(alignment: .leading, spacing: 4) {
                    Text(transactionRow.title)
                        .lineLimit(1)
                    Text(transactionRow.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(transactionRow.amountText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(transactionRow.transactionType == .debit ? .red : .green)
            }
        }
        .navigationTitle(card.name)
        .task {
            await viewModel.loadTransactions(for: card.id)
        }
    }
}
