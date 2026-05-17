import FinanceCore
import FinanceUI
import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel?
    @State private var isLoading = true

    private let appContainer = AppContainer.shared

    var body: some View {
        if let viewModel {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if let totals = viewModel.currentTotals {
                        summaryCards(totals)
                    }

                    if !viewModel.monthlySummaries.isEmpty {
                        chartSection
                    }

                    if !viewModel.recentTransactions.isEmpty {
                        recentTransactionsSection
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.base)
            .task {
                await viewModel.load()
                isLoading = false
            }
        } else {
            VStack {
                ProgressView("Loading Dashboard...")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.base)
            .task {
                let dashboardViewModel = DashboardViewModel(
                    spendingService: appContainer.spendingService,
                    transactionRepository: appContainer.transactionRepository
                )
                viewModel = dashboardViewModel
            }
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSText("Dashboard", style: .headingLarge)
            FDSText("This Month", style: .labelSmall, color: .tertiary)
        }
    }

    func summaryCards(_ totals: SpendingTotals) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                FDSText("Total Debits", style: .labelSmall, color: .tertiary)
                FDSText(formatAmount(totals.totalDebit), style: .headingMedium, color: .debit)
            }
            .padding(AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)

            VStack(alignment: .leading, spacing: 8) {
                FDSText("Total Credits", style: .labelSmall, color: .tertiary)
                FDSText(formatAmount(totals.totalCredit), style: .headingMedium, color: .credit)
            }
            .padding(AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)

            VStack(alignment: .leading, spacing: 8) {
                FDSText("Transactions", style: .labelSmall, color: .tertiary)
                FDSText("\(totals.transactionCount)", style: .headingMedium, color: .accent)
            }
            .padding(AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)
        }
    }

    var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FDSText("6-Month Trend", style: .captionLarge, color: .secondary)

            if let viewModel {
                SpendingTrendChart(monthlySummaries: viewModel.monthlySummaries)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }

    var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                FDSText("Recent Activity", style: .captionLarge, color: .secondary)
                Spacer()

                NavigationLink(destination: TransactionsView(
                    viewModel: TransactionsViewModel(
                        transactionRepository: appContainer.transactionRepository,
                        ledgerRepository: appContainer.ledgerRepository
                    )
                )) {
                    HStack(spacing: 4) {
                        FDSText("View All", style: .labelSmall, color: .accent)
                        Image(systemName: "chevron.right").labelSmall()
                    }
                }
            }

            VStack(spacing: 8) {
                ForEach(viewModel?.recentTransactions.prefix(5) ?? [], id: \.id) { txn in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(txn.transactionType == .debit ? AppColors.debit : AppColors.credit)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            FDSText(txn.description, style: .captionLarge, color: .primary)
                                .lineLimit(1)

                            FDSText(dateString(txn.postedAt), style: .labelSmall, color: .tertiary)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            FDSAmount(
                                formatAmount(txn.amountMinorUnits),
                                type: txn.transactionType == .debit ? .debit : .credit
                            )

                            Text(txn.transactionType == .debit ? "Dr" : "Cr")
                                .labelSmall()
                                .padding(.vertical, 2)
                                .padding(.horizontal, 4)
                                .background(txn.transactionType == .debit ? AppColors.debit
                                    .opacity(0.15) : AppColors.credit.opacity(0.15))
                                .foregroundColor(txn.transactionType == .debit ? AppColors.debit : AppColors.credit)
                                .cornerRadius(AppRadius.sm)
                        }
                    }
                    .padding(AppSpacing.xs)
                    .background(AppColors.surface2)
                    .cornerRadius(AppRadius.md)
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
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
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    DashboardView()
}
