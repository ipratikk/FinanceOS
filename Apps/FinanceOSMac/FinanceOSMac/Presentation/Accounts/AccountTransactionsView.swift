import FinanceCore
import FinanceUI
import SwiftUI

struct AccountTransactionsView: View {
    let ledger: Ledger
    @State private var viewModel: AccountTransactionsViewModel

    init(ledger: Ledger, viewModel: AccountTransactionsViewModel) {
        self.ledger = ledger
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            accountHeader
            TransactionListContentView(
                sections: viewModel.sections,
                listState: viewModel.listState,
                onDelete: { id in
                    Task { await viewModel.deleteTransaction(
                        id: id,
                        accountID: ledger.id,
                        bankId: ledger.bankId,
                        closingBalance: ledger.closingBalance
                    ) }
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
            await viewModel.loadTransactions(
                for: ledger.id,
                bankId: ledger.bankId,
                closingBalance: ledger.closingBalance
            )
        }
    }

    private var accountHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                FDSImage(
                    imageName: viewModel.bank?.symbolAssetName,
                    fallbackSymbol: "building.columns.fill",
                    height: 52,
                    width: 52
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel(viewModel.bank?.name ?? "Bank")
                        .font(AppTypography.bodySmMedium)
                        .foregroundStyle(.secondary)

                    FDSLabel(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    FDSLabel("\((ledger.accountType ?? "Account").capitalized) · •••• \(ledger.last4)")
                        .font(AppTypography.captionSm.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    FDSLabel("Balance")
                        .font(AppTypography.captionSmMedium)
                        .tracking(0.2)
                        .foregroundStyle(.tertiary)

                    if let balanceText = viewModel.closingBalanceText(for: ledger) {
                        FDSLabel(balanceText)
                            .font(AppTypography.amountLarge)
                            .foregroundStyle(AppColors.accentIce)
                            .lineLimit(1)

                        if let dateText = viewModel.closingDateText(for: ledger) {
                            FDSLabel("as of \(dateText)")
                                .font(AppTypography.captionSm)
                                .foregroundStyle(.quaternary)
                        }
                    } else {
                        FDSLabel("—")
                            .font(AppTypography.headingSmall)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(.regularMaterial)

            Divider().opacity(0.3)
        }
    }
}
