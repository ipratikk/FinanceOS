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
                        .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.base)
            } else if viewModel.transactionRows.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(Color(red: 0.518, green: 0.541, blue: 0.580).opacity(0.4))
                    Text("No Transactions")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                    Text("Import statements to get started")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
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
                                    .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                                Text("\(viewModel.transactionRows.count) total")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                            }
                            Spacer()
                        }

                        Text("Transactions list")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
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

    private func sectionHeader(_ date: Date) -> some View {
        Text(dateHeaderString(date))
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color(red: 0.518, green: 0.541, blue: 0.580))
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
                        .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                    Text(dateString(txn.postedAt))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                }
                Spacer()
                Text(txn.amountText)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(txn.transactionType == .debit ? Color(red: 1.0, green: 0.27, blue: 0.23) : Color(
                        red: 0.19,
                        green: 0.82,
                        blue: 0.35
                    ))
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
