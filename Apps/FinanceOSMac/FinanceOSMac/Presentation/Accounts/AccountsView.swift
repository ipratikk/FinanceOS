import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct AccountsView: View {
    @State private var viewModel: AccountsViewModel
    @State private var accountPendingDelete: Ledger?
    @Environment(AppNavigator.self) private var navigator
    private let transactionRepository: any TransactionRepository
    private let ledgerRepository: any LedgerRepository

    init(
        viewModel: AccountsViewModel,
        transactionRepository: any TransactionRepository,
        ledgerRepository: any LedgerRepository
    ) {
        _viewModel = State(initialValue: viewModel)
        self.transactionRepository = transactionRepository
        self.ledgerRepository = ledgerRepository
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
        .navigationTitle("Accounts")
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
            Text(
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
                Text(error)
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
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                listHeader

                ForEach(
                    groupedAccountsByBank.sorted(by: { $0.key < $1.key }),
                    id: \.key
                ) { bankName, ledgers in
                    bankSection(bankName: bankName, ledgers: ledgers)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.xl)
        }
    }

    private var listHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Bank Accounts")
                .font(AppTypography.headingLg)
                .foregroundStyle(.primary)
            Text("Manage your accounts and balances")
                .font(AppTypography.labelMedium)
                .tracking(0.5)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bankSection(bankName: String, ledgers: [Ledger]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(bankName)
                    .font(AppTypography.headlineMd)
                    .foregroundStyle(.primary)
                Text("\(ledgers.count) account\(ledgers.count == 1 ? "" : "s")")
                    .font(AppTypography.labelMedium)
                    .foregroundStyle(.tertiary)
            }

            VStack(spacing: AppSpacing.xs) {
                ForEach(Array(ledgers.enumerated()), id: \.element.id) { _, ledger in
                    NavigationLink(value: DetailDestination.accountTransactions(ledger.id)) {
                        accountRow(ledger)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var groupedAccountsByBank: [String: [Ledger]] {
        Dictionary(grouping: viewModel.accounts) { ledger in
            viewModel.banks.first { $0.id == ledger.bankId }?.name ?? "Unknown"
        }
    }

    private func accountRow(_ ledger: Ledger) -> some View {
        let bank = viewModel.banks.first { $0.id == ledger.bankId }
        let balance = viewModel.balancesByAccount[ledger.id]
        return FDSRow {
            FDSImage(
                imageName: bank?.symbolAssetName,
                fallbackSymbol: "building.columns.fill",
                height: 44,
                width: 44
            )
        } content: {
            VStack(alignment: .leading, spacing: 6) {
                Text(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                    .font(AppTypography.bodySmMedium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text((ledger.accountType ?? "Account").capitalized)
                        .font(AppTypography.captionSm)
                    if !ledger.last4.isEmpty {
                        Text("· •••• \(ledger.last4)")
                            .font(AppTypography.captionSm.monospacedDigit())
                    }
                }
                .foregroundStyle(.tertiary)

                if let balance {
                    Text(balance.formattedBalance)
                        .font(AppTypography.bodySmMedium.monospacedDigit())
                        .foregroundStyle(AppColors.accentIce)
                        .lineLimit(1)
                }
            }
        } trailing: {
            HStack(spacing: AppSpacing.compact) {
                iconButton("plus", color: AppColors.accentGold) {
                    navigator.pendingImportTarget = .ledger(ledger.id)
                    navigator.pendingImportSource = importSource(for: ledger, bank: bank)
                    navigator.navigate(to: .importStatement)
                }
                iconButton("pencil", color: AppColors.accentSlate) {
                    navigator.present(.accountEdit(ledger))
                }
                iconButton("trash", color: AppColors.danger) {
                    accountPendingDelete = ledger
                }
            }
        }
    }

    private func importSource(for ledger: Ledger, bank: Bank?) -> StatementSource? {
        guard let bankEnum = bank?.bank else { return nil }
        switch (bankEnum, ledger.kind) {
        case (.hdfc, .bankAccount): return .hdfcBank
        case (.hdfc, .creditCard): return .hdfcCard
        case (.icici, .bankAccount): return .iciciBank
        case (.icici, .creditCard): return .iciciCard
        case (.amex, _): return .amex
        default: return nil
        }
    }

    private func iconButton(
        _ symbol: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(AppTypography.captionLgSemibold)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(Circle().fill(color.opacity(0.1)))
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
    }

    private func bankName(for ledger: Ledger) -> String {
        viewModel.banks.first { $0.id == ledger.bankId }?.name ?? "Bank"
    }

    private var emptyState: some View {
        FDSEmptyState(
            symbol: "building.columns",
            title: "No Accounts",
            subtitle: "Import a statement to get started"
        )
    }

    private var loadingState: some View {
        ScrollView {
            VStack(spacing: AppSpacing.compact) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    skeletonRow
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.xl)
        }
    }

    private var skeletonRow: some View {
        HStack(spacing: AppSpacing.md) {
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 11)
                    .frame(maxWidth: 160)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 9)
                    .frame(maxWidth: 110)
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(.ultraThinMaterial)
        }
    }
}
