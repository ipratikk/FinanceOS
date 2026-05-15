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
        .background(AppColors.base)
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
                    .foregroundColor(AppColors.textTertiary)
            }

            HStack(spacing: 12) {
                Text("Transactions: \(viewModel.sections.map(\.rows.count).reduce(0, +))")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppColors.textTertiary)

                Spacer()
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .border(AppColors.surface2, width: 1)
    }
}
