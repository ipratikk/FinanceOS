import FinanceCore
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
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            Text("ACCOUNTS")
                .labelSmall()
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            Text("Bank Accounts")
                .displayMedium()
        }
    }

    private func bankSection(bankName: String, ledgers: [Ledger]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            FDSSectionHeader(bankName, subtitle: "\(ledgers.count) account\(ledgers.count == 1 ? "" : "s")")

            VStack(spacing: 0) {
                ForEach(Array(ledgers.enumerated()), id: \.element.id) { index, ledger in
                    NavigationLink(value: DetailDestination.accountTransactions(ledger.id)) {
                        accountRow(ledger)
                    }
                    .buttonStyle(.plain)

                    if index < ledgers.count - 1 {
                        Divider()
                            .opacity(0.3)
                            .padding(.leading, 64)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
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
        HStack(spacing: AppSpacing.md) {
            FDSMerchantAvatar(
                name: bankName(for: ledger),
                symbol: "building.columns.fill",
                size: 36
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                    .caption()
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text((ledger.accountType ?? "Account").capitalized)
                        .font(.system(size: 11, weight: .regular))
                    if !ledger.last4.isEmpty {
                        Text("· •••• \(ledger.last4)")
                            .font(.system(size: 11, weight: .regular).monospacedDigit())
                    }
                }
                .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .labelSmall()
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.compact)
        .contentShape(Rectangle())
    }

    private func bankName(for ledger: Ledger) -> String {
        viewModel.banks.first { $0.id == ledger.bankId }?.name ?? "Bank"
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "building.columns")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: AppSpacing.tight) {
                Text("No Accounts")
                    .bodyLarge()
                Text("Import a statement to get started")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
