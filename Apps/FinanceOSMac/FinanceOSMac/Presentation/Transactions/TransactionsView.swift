//
//  TransactionsView.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import SwiftUI

struct TransactionsView: View {
    @State private var viewModel: TransactionsViewModel

    init(
        viewModel: TransactionsViewModel
    ) {
        _viewModel = State(
            initialValue: viewModel
        )
    }

    var body: some View {
        NavigationStack {
            TransactionListContentView(
                sections: viewModel.sections,
                listState: viewModel.listState
            )
            .navigationTitle("Transactions")
        }
        .task {
            await viewModel.loadTransactions()
        }
    }
}
