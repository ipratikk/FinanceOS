//
//  TransactionsView.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import FinanceUI
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
        Group {
            if viewModel.isLoading, viewModel.transactionRows.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading transactions...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignTokens.Text.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.base)
            } else if viewModel.transactionRows.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(DesignTokens.Text.tertiary.opacity(DesignTokens.Opacity.muted))
                    Text("No Transactions")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignTokens.Text.primary)
                    Text("Import statements to get started")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(DesignTokens.Text.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.base)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Transactions")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(DesignTokens.Text.primary)
                                Text("\(viewModel.transactionRows.count) total")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(DesignTokens.Text.secondary)
                            }
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(
                                groupedTransactions.sorted(by: { $0.key > $1.key }),
                                id: \.key
                            ) { date, transactions in
                                sectionHeader(date)
                                VStack(spacing: 8) {
                                    ForEach(transactions, id: \.id) { txn in
                                        transactionRow(txn)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
                }
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

    private var groupedTransactions: [Date: [TransactionRow]] {
        Dictionary(grouping: viewModel.transactionRows) { txn in
            Calendar.current.startOfDay(for: txn.postedAt)
        }
    }

    private func sectionHeader(_ date: Date) -> some View {
        Text(dateHeaderString(date))
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(DesignTokens.Text.tertiary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppColors.base)
    }

    private func transactionRow(_ txn: TransactionRow) -> some View {
        FDSCard(cornerRadius: 12, padded: false) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(txn.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignTokens.Text.primary)
                    Text(dateString(txn.postedAt))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(DesignTokens.Text.secondary)
                }
                Spacer()
                Text(txn.amountText)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(txn.transactionType == .debit ? DesignTokens.System.red : DesignTokens.System
                        .green)
            }
            .padding(12)
        }
    }

    private func formatAmount(_ minorUnits: Int64) -> String {
        let amount = Double(minorUnits) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        return formatter.string(from: NSNumber(value: amount)) ?? "₹0.00"
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d · h:mm a"
        return formatter.string(from: date)
    }

    private func dateHeaderString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date).uppercased()
    }
}
