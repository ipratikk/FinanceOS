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
        VStack(spacing: 0) {
            cardHeader
            TransactionListContentView(
                sections: viewModel.sections,
                listState: viewModel.listState
            )
        }
        .background(AppColors.base)
        .task {
            await viewModel.loadTransactions(for: card.id)
        }
    }

    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.nickname.isEmpty ? card.cardName : card.nickname)
                    .headingMedium()

                Text("\(card.cardType.rawValue.uppercased()) • ••••\(card.cardLast4)")
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
