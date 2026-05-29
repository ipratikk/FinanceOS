import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct AccountsView: View {
    @State private var viewModel: AccountsViewModel
    @State private var accountPendingDelete: Ledger?
    @Environment(AppNavigator.self) private var navigator

    init(viewModel: AccountsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.accounts.isEmpty, !viewModel.isLoading {
                emptyState
            } else if viewModel.isLoading {
                loadingState
            } else {
                accountsList
            }
        }
        .background(AppColors.base)
        .alert(
            "Delete \"\(accountPendingDelete?.displayName ?? "")\"?",
            isPresented: Binding(
                get: { accountPendingDelete != nil },
                set: { if !$0 { accountPendingDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { accountPendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let ledger = accountPendingDelete {
                    accountPendingDelete = nil
                    Task { await viewModel.deleteAccount(id: ledger.id) }
                }
            }
        } message: {
            FDSLabel(
                "This will permanently delete this account and all associated transactions. This cannot be undone."
            )
        }
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
        .onAppear {
            navigator.accountReloadCallback = {
                await viewModel.loadAccounts()
            }
        }
        .task {
            await viewModel.loadAccounts()
        }
    }

    private var accountsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                listHeader

                ForEach(viewModel.groupedAccountsByBank, id: \.bankName) { bankName, ledgers in
                    bankSection(bankName: bankName, ledgers: ledgers)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
    }

    private var listHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel("Bank Accounts")
                .font(AppTypography.headingXL)
                .foregroundColor(AppColors.Text.primary)
            FDSLabel("Manage your accounts and balances")
                .font(AppTypography.captionLgMedium)
                .tracking(0.2)
                .foregroundColor(AppColors.Text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        FDSEmptyState(
            symbol: "building.columns",
            title: "No Accounts",
            subtitle: "Import a statement to get started"
        )
    }
}

extension AccountsView {
    private func bankSection(bankName: String, ledgers: [Ledger]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                FDSLabel(bankName)
                    .font(AppTypography.bodyMdSemibold)
                    .foregroundColor(AppColors.Text.primary)
                FDSLabel("\(ledgers.count) account\(ledgers.count == 1 ? "" : "s")")
                    .font(AppTypography.captionLgMedium)
                    .foregroundColor(AppColors.Text.secondary)
            }

            VStack(spacing: 4) {
                ForEach(Array(ledgers.enumerated()), id: \.element.id) { _, ledger in
                    NavigationLink(value: DetailDestination.accountTransactions(ledger.id)) {
                        accountRow(ledger)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func accountRow(_ ledger: Ledger) -> some View {
        FDSCard(cornerRadius: 12, padded: false) {
            VStack(alignment: .leading, spacing: 0) {
                accountRowHeader(ledger)
                Divider().opacity(0.2).padding(.horizontal, 12)
                accountRowActions(ledger)
            }
        }
    }

    private func accountRowHeader(_ ledger: Ledger) -> some View {
        let bank = viewModel.banks.first { $0.id == ledger.bankId }
        let balance = viewModel.balancesByAccount[ledger.id]

        return HStack(spacing: 16) {
            FDSBankMark(bank?.bank ?? .hdfc)
                .frame(width: AppSpacing.xxxl, height: AppSpacing.xxxl)

            VStack(alignment: .leading, spacing: 2) {
                FDSLabel(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                    .font(AppTypography.bodySmSemibold)
                    .foregroundColor(AppColors.Text.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    FDSLabel((ledger.accountType ?? "Account").capitalized)
                        .font(AppTypography.captionSmMedium)
                    if !ledger.last4.isEmpty {
                        FDSLabel("•••• \(ledger.last4)")
                            .maskedAccount()
                    }
                }
                .foregroundColor(AppColors.Text.secondary)
            }

            Spacer()

            if let balance {
                VStack(alignment: .trailing, spacing: 2) {
                    FDSLabel(balance.formattedBalance)
                        .font(AppTypography.amountSm)
                        .foregroundColor(AppColors.success)
                }
            }
        }
        .padding(AppSpacing.xs)
    }

    private func accountRowActions(_ ledger: Ledger) -> some View {
        HStack(spacing: 12) {
            Spacer()

            actionIconButton("plus", color: AppColors.Text.tertiary) {
                navigator.pendingImportTarget = .ledger(ledger.id)
                navigator.pendingImportSource = viewModel.statementSource(for: ledger)
                navigator.navigate(to: .importStatement)
            }

            actionIconButton("pencil", color: AppColors.Text.tertiary) {
                navigator.present(.accountEdit(ledger))
            }

            actionIconButton("trash", color: AppColors.danger) {
                accountPendingDelete = ledger
            }
        }
        .padding(8)
    }

    private func actionIconButton(
        _ symbol: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(AppTypography.captionLgSemibold)
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(Circle().fill(color.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .frame(minWidth: 32, minHeight: 32)
        .contentShape(Rectangle())
    }

    private var loadingState: some View {
        ScrollView {
            VStack(spacing: 4) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    skeletonRow
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
    }

    private var skeletonRow: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(AppColors.Glass.thinTint)
                .frame(width: AppSpacing.xxxl, height: AppSpacing.xxxl)
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.Glass.thinTint)
                    .frame(height: 11)
                    .frame(maxWidth: 160)
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.Glass.thinTint)
                    .frame(height: 9)
                    .frame(maxWidth: 110)
            }
            Spacer()
        }
        .padding(AppSpacing.xs)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.Glass.surface)
        }
    }
}
