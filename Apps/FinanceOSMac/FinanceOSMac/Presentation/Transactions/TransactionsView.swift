//
//  TransactionsView.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

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
            List(viewModel.transactionRows) { transactionRow in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transactionRow.title)
                        Text(transactionRow.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(transactionRow.amountText)
                        .font(.subheadline.monospacedDigit())
                }
            }
            .navigationTitle("Transactions")
        }
        .task {
            await viewModel.loadTransactions()
        }
    }
}
