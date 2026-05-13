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
                NavigationLink(destination: AccountTransactionsView(
                    account: account,
                    viewModel: AccountTransactionsViewModel(
                        transactionRepository: appContainer.transactionRepository,
                        cardRepository: appContainer.cardRepository
                    )
                )) {
                    Text(account.name)
                }
            }
            .navigationTitle("Accounts")
        }
        .task {
            await viewModel.loadAccounts()
        }
    }
}
