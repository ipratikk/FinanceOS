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

    private func networkLogo(for cardType: String) -> NSImage? {
        let assetNames: [String: String] = [
            "visa": "visa",
            "mastercard": "mastercard",
            "amex": "amex",
            "rupay": "rupay",
            "diners": "diners"
        ]

        if let assetName = assetNames[cardType.lowercased()],
           let nsImage = NSImage(named: assetName)
        {
            return nsImage
        }

        return nil
    }

    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                    .headingMedium()

                HStack(spacing: 8) {
                    if let cardType = ledger.cardType {
                        if let logo = networkLogo(for: cardType) {
                            Image(nsImage: logo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 12)
                        }

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
