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
                Text(account.name)
            }
            .navigationTitle("Accounts")
        }
        .task {
            await viewModel.loadAccounts()
        }
    }
}
