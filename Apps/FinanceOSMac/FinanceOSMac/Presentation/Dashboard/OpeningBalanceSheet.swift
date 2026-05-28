import FinanceCore
import FinanceUI
import SwiftUI

struct OpeningBalanceSheet: View {
    let viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editingLedger: Ledger?
    @State private var balanceInput: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            Divider().opacity(0.1)
            ledgerListContent
        }
        .frame(minWidth: 480, minHeight: 360)
        .background(AppColors.base)
        .sheet(item: $editingLedger) { ledger in
            editBalanceSheet(for: ledger)
        }
    }

    private var headerRow: some View {
        HStack {
            FDSLabel("Opening Balances")
                .font(AppTypography.headingMd)
                .foregroundStyle(AppColors.Text.primary)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppColors.Text.quaternary)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.xl)
    }

    @ViewBuilder
    private var ledgerListContent: some View {
        if viewModel.ledgers.isEmpty {
            FDSLabel("No accounts found")
                .font(AppTypography.bodyMd)
                .foregroundStyle(AppColors.Text.tertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(viewModel.ledgers) { ledger in
                ledgerRow(ledger)
            }
            .listStyle(.plain)
        }
    }

    private func ledgerRow(_ ledger: Ledger) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                FDSLabel(ledger.displayName)
                    .font(AppTypography.bodySmMedium)
                    .foregroundStyle(AppColors.Text.primary)
                FDSLabel(ledger.kind.displayName)
                    .font(AppTypography.captionSm)
                    .foregroundStyle(AppColors.Text.tertiary)
            }
            Spacer()
            if let balance = ledger.openingBalance {
                FDSLabel(FormatterCache.formatCurrency(Decimal(balance) / 100, currencyCode: "INR"))
                    .font(AppTypography.bodySmSemibold)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.Text.secondary)
            } else {
                FDSLabel("Not set")
                    .font(AppTypography.captionLg)
                    .foregroundStyle(AppColors.Text.quaternary)
            }
            Button("Edit") {
                let current = ledger.openingBalance.map { Decimal($0) / 100 } ?? 0
                balanceInput = current == 0 ? "" : "\(current)"
                editingLedger = ledger
            }
            .buttonStyle(.plain)
            .font(AppTypography.captionLgSemibold)
            .foregroundStyle(AppColors.accent)
        }
        .padding(.vertical, 8)
    }

    private func editBalanceSheet(for ledger: Ledger) -> some View {
        VStack(spacing: AppSpacing.xl) {
            FDSLabel("Set Opening Balance")
                .font(AppTypography.headingMd)
                .foregroundStyle(AppColors.Text.primary)
            FDSLabel(ledger.displayName)
                .font(AppTypography.bodyMd)
                .foregroundStyle(AppColors.Text.secondary)
            TextField("Amount in ₹", text: $balanceInput)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
            HStack(spacing: AppSpacing.md) {
                Button("Cancel") { editingLedger = nil }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppColors.Text.secondary)
                Button("Save") {
                    let amount = Decimal(string: balanceInput) ?? 0
                    let minorUnits = Int64((amount * 100 as NSDecimalNumber).int64Value)
                    Task {
                        await viewModel.updateOpeningBalance(ledgerId: ledger.id, balanceMinorUnits: minorUnits)
                        editingLedger = nil
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(AppSpacing.xxxl)
        .frame(width: 360)
        .background(AppColors.base)
    }
}
