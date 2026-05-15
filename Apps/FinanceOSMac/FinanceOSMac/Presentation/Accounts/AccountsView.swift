import FinanceCore
import SwiftUI

struct AccountsView: View {
    @State private var viewModel: AccountsViewModel
    @State private var selectedAccountId: UUID?
    private let transactionRepository: any TransactionRepository
    private let cardRepository: any CardRepository

    init(
        viewModel: AccountsViewModel,
        transactionRepository: any TransactionRepository,
        cardRepository: any CardRepository
    ) {
        _viewModel = State(initialValue: viewModel)
        self.transactionRepository = transactionRepository
        self.cardRepository = cardRepository
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
        .sheet(item: $viewModel.editingAccount) { account in
            AccountEditView(account: account, viewModel: viewModel)
        }
        .task {
            await viewModel.loadAccounts()
        }
    }

    var accountsList: some View {
        List {
            ForEach(
                groupedAccountsByBank.sorted(by: { $0.key < $1.key }),
                id: \.key
            ) { bankName, accounts in
                Section(bankName) {
                    ForEach(accounts, id: \.id) { account in
                        NavigationLink(value: account.id) {
                            accountRow(account)
                        }
                        .listRowBackground(AppColors.surface)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.editingAccount = account
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button("Edit") { viewModel.editingAccount = account }
                            Button("Delete", role: .destructive) {
                                viewModel.editingAccount = account
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
            if let account = viewModel.accounts.first(where: { $0.id == accountId }) {
                AccountTransactionsView(
                    account: account,
                    viewModel: AccountTransactionsViewModel(
                        transactionRepository: transactionRepository,
                        cardRepository: cardRepository
                    )
                )
                .navigationTitle(account.accountName)
                .onAppear { selectedAccountId = accountId }
            }
        }
    }

    private var groupedAccountsByBank: [String: [Account]] {
        Dictionary(grouping: viewModel.accounts) { account in
            viewModel.banks.first { $0.id == account.bankId }?.name ?? "Unknown"
        }
    }

    func accountRow(_ account: Account) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.nickname.isEmpty ? account.accountName : account.nickname)
                    .font(.system(size: 14, weight: .semibold))

                Text(account.accountType.rawValue.uppercased())
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            Text("••••\(account.accountLast4)")
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
                    .font(.system(size: 16, weight: .semibold))

                Text("Import a statement to get started")
                    .font(.system(size: 13, weight: .regular))
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
