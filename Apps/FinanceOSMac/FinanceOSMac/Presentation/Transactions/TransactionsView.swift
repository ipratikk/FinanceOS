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
        TransactionListContentView(
            sections: viewModel.sections,
            listState: viewModel.listState,
            onDelete: { id in
                Task { await viewModel.deleteTransaction(id: id) }
            }
        )
        .overlay {
            if viewModel.isLoading, viewModel.transactionRows.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading transactions...")
                        .caption()
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.base)
            }
        }
        .navigationTitle("Transactions")
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
            await viewModel.loadTransactions()
        }
    }
}
