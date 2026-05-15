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
        VStack(spacing: 0) {
            accountHeader
            TransactionListContentView(
                sections: viewModel.sections,
                listState: viewModel.listState
            )
        }
        .background(Color(red: 0.051, green: 0.051, blue: 0.059))
        .task {
            await viewModel.loadTransactions(for: account.id)
        }
    }

    private var accountHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.nickname.isEmpty ? account.accountName : account.nickname)
                    .font(.system(size: 18, weight: .semibold))

                Text("\(account.accountType.rawValue.uppercased()) • ••••\(account.accountLast4)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
            }

            HStack(spacing: 12) {
                Text("Transactions: \(viewModel.sections.map(\.rows.count).reduce(0, +))")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))

                Spacer()
            }
        }
        .padding(16)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .border(Color(red: 0.110, green: 0.110, blue: 0.122), width: 1)
    }
}
