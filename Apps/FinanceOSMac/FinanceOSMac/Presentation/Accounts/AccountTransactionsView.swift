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
                Text(error)
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
                    Text(viewModel.bank?.name ?? "Bank")
                        .font(AppTypography.bodySmMedium)
                        .foregroundStyle(.secondary)

                    Text(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("\((ledger.accountType ?? "Account").capitalized) · •••• \(ledger.last4)")
                        .font(AppTypography.captionSm.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Balance")
                        .font(AppTypography.labelMedium)
                        .tracking(0.5)
                        .foregroundStyle(.tertiary)

                    if let balance = ledger.closingBalance {
                        Text(formattedBalance(balance))
                            .font(AppTypography.displaySmall.monospacedDigit())
                            .foregroundStyle(AppColors.accentIce)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        if let asOf = ledger.closingBalanceAsOf {
                            Text("as of \(formattedDate(asOf))")
                                .font(AppTypography.label)
                                .foregroundStyle(.quaternary)
                        }
                    } else {
                        Text("—")
                            .font(AppTypography.displaySmall)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(.regularMaterial)

            Divider().opacity(0.3)
        }
    }

    private func formattedBalance(_ minorUnits: Int64) -> String {
        let whole = minorUnits / 100
        let frac = abs(minorUnits % 100)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        let formatted = formatter.string(from: NSNumber(value: whole)) ?? "\(whole)"
        return "₹\(formatted).\(String(format: "%02d", frac))"
    }

    private func formattedDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM yyyy"
        return fmt.string(from: date)
    }
}
