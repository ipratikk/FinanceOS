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
        .background(Color(red: 0.051, green: 0.051, blue: 0.059))
        .task {
            await viewModel.loadTransactions(for: card.id)
        }
    }

    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.nickname.isEmpty ? card.cardName : card.nickname)
                    .font(.system(size: 18, weight: .semibold))

                Text("\(card.cardType.rawValue.uppercased()) • ••••\(card.cardLast4)")
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
