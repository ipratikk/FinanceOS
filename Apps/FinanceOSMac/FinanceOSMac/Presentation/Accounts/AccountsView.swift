//
//  AccountsView.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import SwiftUI

struct AccountsView: View {
    @State private var viewModel: AccountsViewModel
    @State private var selectedAccountId: UUID?
    private let appContainer = AppContainer.shared

    init(
        viewModel: AccountsViewModel
    ) {
        _viewModel = State(
            initialValue: viewModel
        )
    }

    var body: some View {
        NavigationStack {
            List(viewModel.accounts) { account in
                NavigationLink(value: account.id) {
                    let displayName = account.nickname.isEmpty ? account.name : account.nickname
                    let institutionName = viewModel.institutions.first { $0.id == account.institutionID }?.name ?? "Unknown"
                    Text("\(institutionName) \(displayName)")
                }
                .contextMenu {
                    Button("Edit") {
                        viewModel.editingAccount = account
                    }
                    Button("Delete", role: .destructive) {
                        viewModel.editingAccount = account
                    }
                }
            }
            .navigationDestination(for: UUID.self) { accountId in
                if let account = viewModel.accounts.first(where: { $0.id == accountId }) {
                    AccountTransactionsView(
                        account: account,
                        viewModel: AccountTransactionsViewModel(
                            transactionRepository: appContainer.transactionRepository,
                            cardRepository: appContainer.cardRepository
                        )
                    )
                    .navigationTitle(account.name)
                    .onAppear {
                        selectedAccountId = accountId
                    }
                }
            }
        }
        .navigationTitle("Accounts")
        .sheet(item: $viewModel.editingAccount) { account in
            AccountEditView(
                account: account,
                viewModel: viewModel
            )
        }
        .task {
            await viewModel.loadAccounts()
        }
    }
}
