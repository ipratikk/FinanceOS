import FinanceCore
import SwiftUI

struct CardTransactionsView: View {
    let ledger: Ledger
    @State private var viewModel: CardTransactionsViewModel

    init(
        ledger: Ledger,
        viewModel: CardTransactionsViewModel
    ) {
        self.ledger = ledger
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            cardHeader
            TransactionListContentView(
                sections: viewModel.sections,
                listState: viewModel.listState,
                onDelete: { id in
                    Task { await viewModel.deleteTransaction(id: id, cardID: ledger.id) }
                }
            )
        }
        .background(AppColors.base)
        .alert("Delete Failed", isPresented: Binding(
            get: { viewModel.deleteError != nil },
            set: { if !$0 { viewModel.deleteError = nil } }
        )) {
            Button("OK") { viewModel.deleteError = nil }
        } message: {
            if let error = viewModel.deleteError {
                Text(error)
            }
        }
        .task {
            await viewModel.loadTransactions(for: ledger.id)
        }
    }

    private func networkLogoURL(for cardType: String) -> URL? {
        let urls: [String: String] = [
            "visa": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Visa_Inc._logo.svg/1200px-Visa_Inc._logo.svg.png",
            "mastercard": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/1024px-Mastercard-logo.svg.png",
            "rupay": "https://upload.wikimedia.org/wikipedia/en/6/6d/RuPay_logo.svg",
            "discover": "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Discover_Card_logo.svg/1024px-Discover_Card_logo.svg.png"
        ]
        return urls[cardType.lowercased()].flatMap { URL(string: $0) }
    }

    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                    .headingMedium()

                HStack(spacing: 8) {
                    if let cardType = ledger.cardType {
                        AsyncImage(url: networkLogoURL(for: cardType)) { phase in
                            switch phase {
                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 12)
                            default:
                                EmptyView()
                            }
                        }
                        .frame(width: 24, height: 12)

                        Text(cardType.uppercased())
                            .labelSmall()
                    }

                    Text("• ••••\(ledger.last4)")
                        .labelSmall()
                        .foregroundColor(AppColors.textTertiary)
                }
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
