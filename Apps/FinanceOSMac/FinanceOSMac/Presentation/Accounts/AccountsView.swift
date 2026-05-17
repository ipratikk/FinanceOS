import FinanceCore
import SwiftUI

struct AccountsView: View {
    @State private var viewModel: AccountsViewModel
    @State private var selectedAccountId: UUID?
    @State private var accountPendingDelete: Ledger?
    let selection: NavigationItem?
    private let transactionRepository: any TransactionRepository
    private let ledgerRepository: any LedgerRepository

    init(
        viewModel: AccountsViewModel,
        transactionRepository: any TransactionRepository,
        ledgerRepository: any LedgerRepository,
        selection: NavigationItem? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.transactionRepository = transactionRepository
        self.ledgerRepository = ledgerRepository
        self.selection = selection
    }

    var body: some View {
        NavigationStack {
            if viewModel.accounts.isEmpty, !viewModel.isLoading {
                emptyState
            } else if viewModel.isLoading {
                loadingState
            } else {
                accountsList
            }
        }
        .navigationTitle("Accounts")
        .sheet(item: $viewModel.editingAccount) { ledger in
            AccountEditView(account: ledger, viewModel: viewModel)
        }
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
        .id(selection)
    }

    var accountsList: some View {
        List {
            ForEach(
                groupedAccountsByBank.sorted(by: { $0.key < $1.key }),
                id: \.key
            ) { bankName, ledgers in
                Section(bankName) {
                    ForEach(ledgers, id: \.id) { ledger in
                        NavigationLink(value: ledger.id) {
                            accountRow(ledger)
                        }
                        .listRowBackground(AppColors.surface)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                accountPendingDelete = ledger
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button("Edit") { viewModel.editingAccount = ledger }
                            Button("Delete", role: .destructive) {
                                accountPendingDelete = ledger
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(AppColors.base)
        .scrollContentBackground(.hidden)
        .navigationDestination(for: UUID.self) { accountId in
            if let ledger = viewModel.accounts.first(where: { $0.id == accountId }) {
                AccountTransactionsView(
                    ledger: ledger,
                    viewModel: AccountTransactionsViewModel(
                        transactionRepository: transactionRepository,
                        ledgerRepository: ledgerRepository
                    )
                )
                .navigationTitle(ledger.displayName)
                .onAppear { selectedAccountId = accountId }
            }
        }
    }

    private var groupedAccountsByBank: [String: [Ledger]] {
        Dictionary(grouping: viewModel.accounts) { ledger in
            viewModel.banks.first { $0.id == ledger.bankId }?.name ?? "Unknown"
        }
    }

    func accountRow(_ ledger: Ledger) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                    .monoAmount()

                Text((ledger.accountType ?? "").uppercased())
                    .labelSmall()
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            Text("••••\(ledger.last4)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(AppColors.accent)
        }
        .padding(AppSpacing.sm)
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppColors.textTertiary)

            VStack(spacing: 8) {
                Text("No Accounts")
                    .headingSmall()

                Text("Import a statement to get started")
                    .caption()
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    var loadingState: some View {
        VStack(spacing: 8) {
            ForEach(0 ..< 3, id: \.self) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppColors.surface2)
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.surface2)
                            .frame(height: 12)
                            .frame(maxWidth: 120)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColors.surface2)
                            .frame(height: 10)
                            .frame(maxWidth: 80)
                    }

                    Spacer()
                }
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)
            }
        }
        .padding(AppSpacing.md)
    }
}
