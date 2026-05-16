import FinanceCore
import SwiftUI

struct AccountTransactionsView: View {
    let ledger: Ledger
    @State private var viewModel: AccountTransactionsViewModel

    init(
        ledger: Ledger,
        viewModel: AccountTransactionsViewModel
    ) {
        self.ledger = ledger
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
            await viewModel.loadTransactions(for: ledger.id)
        }
    }

    private var accountHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                    .headingMedium()

                Text("\(ledger.accountType?.rawValue.uppercased() ?? "") • ••••\(ledger.last4)")
                    .labelSmall()
                    .foregroundColor(AppColors.textTertiary)
            }

            HStack(spacing: 12) {
                Text("Transactions: \(viewModel.sections.map(\.rows.count).reduce(0, +))")
                    .labelSmall()
                    .foregroundColor(AppColors.textTertiary)

                Spacer()
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .border(AppColors.surface2, width: 1)
    }
}
