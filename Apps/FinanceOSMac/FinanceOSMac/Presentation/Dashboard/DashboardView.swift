import Charts
import FinanceCore
import FinanceUI
import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel?
    @Environment(AppNavigator.self) private var navigator

    init() {}
    init(viewModel: DashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let viewModel {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Row 1: Net Worth hero + Wealth Intelligence
                        HStack(alignment: .top, spacing: 20) {
                            netWorthHero(viewModel)
                            wealthIntelCard
                                .frame(width: 310)
                        }

                        // Row 2: three metric tiles
                        if let totals = viewModel.currentTotals {
                            metricsRow(totals)
                        }

                        // Row 3: Asset Distribution + Recent Activity
                        HStack(alignment: .top, spacing: 20) {
                            assetDistCard
                                .frame(width: 340)
                            recentActivityCard(viewModel)
                        }
                    }
                    .padding(28)
                }
                .background(AppColors.base)
                .task { await viewModel.load() }
            } else {
                loadingView
                    .task {
                        let c = AppContainer.shared
                        viewModel = DashboardViewModel(
                            spendingService: c.spendingService,
                            transactionRepository: c.transactionRepository
                        )
                    }
            }
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .principal) {
                FDSLabel(currentMonthLabel)
                    .font(AppTypography.bodyMdSemibold)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView().controlSize(.regular)
            FDSLabel("Loading…")
                .font(AppTypography.bodyMd)
                .foregroundStyle(AppColors.Text.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.base)
    }

    // MARK: - Helpers

    var currentMonthLabel: String {
        FormatterCache.formatMonthYear(Date()).uppercased()
    }

    func amount(_ minorUnits: Int64, code: String = "INR") -> String {
        FormatterCache.formatCurrency(Decimal(minorUnits) / 100, currencyCode: code)
    }

    func categoryName(for description: String) -> String {
        let lower = description.lowercased()
        if lower.contains("salary") || lower.contains("deposit") || lower.contains("credit") { return "Income" }
        if lower.contains("food") || lower.contains("market") || lower.contains("grocer") { return "Groceries" }
        if lower.contains("zomato") || lower.contains("swiggy") || lower
            .contains("restaurant") { return "Food & Dining" }
        if lower.contains("amazon") || lower.contains("flipkart") || lower.contains("shop") { return "Shopping" }
        if lower.contains("netflix") || lower.contains("spotify") || lower.contains("prime") { return "Entertainment" }
        if lower.contains("uber") || lower.contains("ola") || lower.contains("fuel") { return "Transport" }
        if lower.contains("apple") || lower.contains("google") { return "Technology" }
        if lower.contains("recharge") || lower.contains("electricity") || lower.contains("bill") { return "Utilities" }
        return "Transfer"
    }

    func dateString(_ date: Date) -> String {
        FormatterCache.formatDateTime(date)
    }
}

#Preview {
    DashboardView()
        .environment(AppNavigator())
}
