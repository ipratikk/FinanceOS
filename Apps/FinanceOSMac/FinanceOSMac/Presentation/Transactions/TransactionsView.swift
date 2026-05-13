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
            List(viewModel.transactionRows) { transactionRow in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: transactionRow
                        .transactionType == .debit ? "arrow.up.left.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(transactionRow.transactionType == .debit ? .red : .green)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(transactionRow.title)
                            .lineLimit(1)
                        Text(transactionRow.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(transactionRow.amountText)
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(transactionRow.transactionType == .debit ? .red : .green)
                }
            }
            .navigationTitle("Transactions")
        }
        .task {
            await viewModel.loadTransactions()
        }
    }
}
