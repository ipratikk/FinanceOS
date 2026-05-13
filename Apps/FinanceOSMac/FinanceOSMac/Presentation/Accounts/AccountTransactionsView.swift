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
        .navigationTitle(account.name)
        .task {
            await viewModel.loadTransactions(for: account.id)
        }
    }
}
