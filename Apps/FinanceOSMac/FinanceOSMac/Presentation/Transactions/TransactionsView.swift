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
                    FDSLabel("Loading transactions...")
                        .font(AppTypography.captionSmMedium)
                        .foregroundColor(AppColors.Text.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.base)
            } else if viewModel.transactionRows.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard.fill")
                        .font(AppTypography.displaySmall)
                        .foregroundColor(AppColors.Text.tertiary.opacity(AppColors.Opacity.muted))
                    FDSLabel("No Transactions")
                        .font(AppTypography.bodySmSemibold)
                        .foregroundColor(AppColors.Text.primary)
                    FDSLabel("Import statements to get started")
                        .font(AppTypography.captionSmMedium)
                        .foregroundColor(AppColors.Text.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.base)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                FDSLabel("Transactions")
                                    .font(AppTypography.headingLg)
                                    .foregroundColor(AppColors.Text.primary)
                                FDSLabel("\(viewModel.transactionRows.count) total")
                                    .font(AppTypography.captionSmMedium)
                                    .foregroundColor(AppColors.Text.secondary)
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
                    .padding(.horizontal, AppSpacing.xl)
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
                FDSLabel(error)
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
        FDSLabel(dateHeaderString(date))
            .font(AppTypography.captionSmSemibold)
            .foregroundColor(AppColors.Text.tertiary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppColors.base)
    }

    private func transactionRow(_ txn: TransactionRow) -> some View {
        FDSCard(cornerRadius: 12, padded: false) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    FDSLabel(txn.title)
                        .font(AppTypography.bodySmSemibold)
                        .foregroundColor(AppColors.Text.primary)
                    FDSLabel(dateString(txn.postedAt))
                        .font(AppTypography.captionSm)
                        .foregroundColor(AppColors.Text.secondary)
                }
                Spacer()
                FDSLabel(txn.amountText)
                    .font(AppTypography.bodySmSemibold)
                    .foregroundColor(txn.transactionType == .debit ? AppColors.System.red : AppColors.System
                        .green)
            }
            .padding(AppSpacing.xs)
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
