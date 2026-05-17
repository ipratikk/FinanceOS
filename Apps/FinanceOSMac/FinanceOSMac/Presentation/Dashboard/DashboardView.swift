import FinanceCore
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
            Text("Dashboard")
                .headingLarge()

            Text("This Month")
                .labelSmall()
                .foregroundColor(AppColors.textTertiary)
        }
    }

    func summaryCards(_ totals: SpendingTotals) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Debits")
                    .labelSmall()
                    .foregroundColor(AppColors.textTertiary)

                Text(formatAmount(totals.totalDebit))
                    .headingMedium()
                    .foregroundColor(AppColors.debit)
            }
            .padding(AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)

            VStack(alignment: .leading, spacing: 8) {
                Text("Total Credits")
                    .labelSmall()
                    .foregroundColor(AppColors.textTertiary)

                Text(formatAmount(totals.totalCredit))
                    .headingMedium()
                    .foregroundColor(AppColors.credit)
            }
            .padding(AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)

            VStack(alignment: .leading, spacing: 8) {
                Text("Transactions")
                    .labelSmall()
                    .foregroundColor(AppColors.textTertiary)

                Text("\(totals.transactionCount)")
                    .headingMedium()
                    .foregroundColor(AppColors.accent)
            }
            .padding(AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)
        }
    }

    var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("6-Month Trend")
                .captionLarge()
                .foregroundColor(.gray)

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
                Text("Recent Activity")
                    .captionLarge()
                    .foregroundColor(.gray)

                Spacer()

                NavigationLink(destination: TransactionsView(
                    viewModel: TransactionsViewModel(
                        transactionRepository: appContainer.transactionRepository,
                        ledgerRepository: appContainer.ledgerRepository
                    )
                )) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .labelSmall()

                        Image(systemName: "chevron.right")
                            .labelSmall()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }

            VStack(spacing: 8) {
                ForEach(viewModel?.recentTransactions.prefix(5) ?? [], id: \.id) { txn in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(txn.transactionType == .debit ? AppColors.debit : AppColors.credit)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(txn.description)
                                .captionLarge()
                                .lineLimit(1)

                            Text(dateString(txn.postedAt))
                                .labelSmall()
                                .foregroundColor(AppColors.textTertiary)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Text(formatAmount(txn.amountMinorUnits))
                                .monoAmount()
                                .foregroundColor(txn.transactionType == .debit ? AppColors.debit : AppColors.credit)

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
