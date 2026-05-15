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
                .padding(16)
            }
            .background(Color(red: 0.051, green: 0.051, blue: 0.059))
            .task {
                await viewModel.load()
                isLoading = false
            }
        } else {
            VStack {
                ProgressView("Loading Dashboard...")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.051, green: 0.051, blue: 0.059))
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
                .font(.system(size: 22, weight: .semibold))

            Text("This Month")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
        }
    }

    func summaryCards(_ totals: SpendingTotals) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Debits")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))

                Text(formatAmount(totals.totalDebit))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.red)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.086, green: 0.086, blue: 0.098))
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 8) {
                Text("Total Credits")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))

                Text(formatAmount(totals.totalCredit))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.green)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.086, green: 0.086, blue: 0.098))
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 8) {
                Text("Transactions")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))

                Text("\(totals.transactionCount)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.231, green: 0.510, blue: 0.980))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.086, green: 0.086, blue: 0.098))
            .cornerRadius(10)
        }
    }

    var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("6-Month Trend")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)

            if let viewModel {
                SpendingTrendChart(monthlySummaries: viewModel.monthlySummaries)
            }
        }
        .padding(12)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .cornerRadius(10)
    }

    var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)

                Spacer()

                NavigationLink(destination: TransactionsView(
                    viewModel: TransactionsViewModel(
                        transactionRepository: appContainer.transactionRepository,
                        accountRepository: appContainer.accountRepository,
                        cardRepository: appContainer.cardRepository
                    )
                )) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 11, weight: .medium))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 0.231, green: 0.510, blue: 0.980))
                }
            }

            VStack(spacing: 8) {
                ForEach(viewModel?.recentTransactions.prefix(5) ?? [], id: \.id) { txn in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(txn.transactionType == .debit ? Color.red : Color.green)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(txn.description)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)

                            Text(dateString(txn.postedAt))
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Text(formatAmount(txn.amountMinorUnits))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(txn.transactionType == .debit ? .red : .green)

                            Text(txn.transactionType == .debit ? "Dr" : "Cr")
                                .font(.system(size: 10, weight: .medium))
                                .padding(.vertical, 2)
                                .padding(.horizontal, 4)
                                .background(txn.transactionType == .debit ? Color.red
                                    .opacity(0.15) : Color.green.opacity(0.15))
                                .foregroundColor(txn.transactionType == .debit ? .red : .green)
                                .cornerRadius(3)
                        }
                    }
                    .padding(10)
                    .background(Color(red: 0.110, green: 0.110, blue: 0.122))
                    .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .cornerRadius(10)
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
