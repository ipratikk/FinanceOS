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
            if viewModel.accounts.isEmpty && !viewModel.isLoading {
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
        ScrollView {
            VStack(spacing: 16) {
                ForEach(Dictionary(grouping: viewModel.accounts) { viewModel.banks.first { $0.id == $1.bankId }?.name ?? "Unknown" }, id: \.key) { bankName, accounts in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(bankName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
                            .padding(.horizontal, 16)

                        VStack(spacing: 8) {
                            ForEach(accounts, id: \.id) { account in
                                NavigationLink(value: account.id) {
                                    accountRow(account)
                                }
                                .contextMenu {
                                    Button("Edit") { viewModel.editingAccount = account }
                                    Button("Delete", role: .destructive) { viewModel.editingAccount = account }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(16)
        }
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

    func accountRow(_ account: Account) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.nickname.isEmpty ? account.accountName : account.nickname)
                    .font(.system(size: 14, weight: .semibold))

                Text(account.accountType.rawValue.uppercased())
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
            }

            Spacer()

            Text("••••\(account.accountLast4)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(red: 0.231, green: 0.510, blue: 0.980))
        }
        .padding(12)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .cornerRadius(10)
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))

            VStack(spacing: 8) {
                Text("No Accounts")
                    .font(.system(size: 16, weight: .semibold))

                Text("Import a statement to get started")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    var loadingState: some View {
        VStack(spacing: 8) {
            ForEach(0 ..< 3, id: \.self) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(red: 0.110, green: 0.110, blue: 0.122))
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.110, green: 0.110, blue: 0.122))
                            .frame(height: 12)
                            .frame(maxWidth: 120)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.110, green: 0.110, blue: 0.122))
                            .frame(height: 10)
                            .frame(maxWidth: 80)
                    }

                    Spacer()
                }
                .padding(12)
                .background(Color(red: 0.086, green: 0.086, blue: 0.098))
                .cornerRadius(10)
            }
        }
        .padding(16)
    }
}
