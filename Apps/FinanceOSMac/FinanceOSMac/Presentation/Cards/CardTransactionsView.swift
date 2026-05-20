import FinanceCore
import FinanceUI
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
                FDSLabel(error)
            }
        }
        .task {
            await viewModel.loadTransactions(for: ledger.id)
        }
    }

    private func networkLogo(for network: CardNetwork) -> NSImage? {
        guard let assetName = network.logoAssetName else { return nil }
        return NSImage(named: assetName)
    }

    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                FDSLabel(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                    .font(AppTypography.headlineMd)
                    .foregroundStyle(.primary)

                HStack(spacing: AppSpacing.compact) {
                    if let cardType = ledger.cardType {
                        if let logo = networkLogo(for: cardType) {
                            Image(nsImage: logo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 12)
                        }

                        FDSLabel(cardType.displayName.uppercased())
                            .font(AppTypography.captionLgMedium)
                            .foregroundStyle(.secondary)
                    }

                    FDSLabel("• ••••\(ledger.last4)")
                        .font(AppTypography.captionLgMedium)
                        .foregroundStyle(.tertiary)
                }
            }

            HStack(spacing: AppSpacing.md) {
                FDSLabel("Transactions: \(viewModel.sections.map(\.rows.count).reduce(0, +))")
                    .font(AppTypography.captionLg)
                    .foregroundStyle(.tertiary)

                Spacer()
            }
        }
        .padding(AppSpacing.md)
        .background(.regularMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .strokeBorder(AppColors.accentSlate.opacity(0.08), lineWidth: 0.5)
        )
    }
}
