import FinanceCore
import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel?
    @State private var isLoading = true

    private let appContainer = AppContainer.shared

    var body: some View {
        if let viewModel {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if let totals = viewModel.currentTotals {
                        summaryCards(totals)
                    }

                    if !viewModel.recentTransactions.isEmpty {
                        recentTransactionsSection
                    }

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Dashboard")
            .task {
                await viewModel.load()
                isLoading = false
            }
        } else {
            VStack {
                ProgressView("Loading Dashboard...")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task {
                let vm = DashboardViewModel(
                    spendingService: appContainer.spendingService,
                    transactionRepository: appContainer.transactionRepository
                )
                viewModel = vm
            }
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dashboard")
                .font(.system(size: 28, weight: .bold))
            Text("Financial Overview")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
        }
    }

    func summaryCards(_ totals: SpendingTotals) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Debits")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                Text(formatAmount(totals.totalDebit))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.red)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.086, green: 0.086, blue: 0.098))
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 8) {
                Text("Total Credits")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                Text(formatAmount(totals.totalCredit))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.green)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.086, green: 0.086, blue: 0.098))
            .cornerRadius(10)
        }
    }

    var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                NavigationLink(destination: TransactionsView(
                    viewModel: TransactionsViewModel(
                        transactionRepository: appContainer.transactionRepository,
                        accountRepository: appContainer.accountRepository,
                        cardRepository: appContainer.cardRepository
                    )
                )) {
                    Text("View All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                }
            }

            VStack(spacing: 8) {
                ForEach(viewModel?.recentTransactions.prefix(5) ?? [], id: \.id) { txn in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(txn.description)
                                .font(.system(size: 14, weight: .medium))
                            Text(dateString(txn.postedAt))
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Text(formatAmount(txn.amountMinorUnits))
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(txn.transactionType == .debit ? .red : .green)
                    }
                    .padding(12)
                    .background(Color(red: 0.086, green: 0.086, blue: 0.098))
                    .cornerRadius(8)
                }
            }
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
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    DashboardView()
}
