import Charts
import FinanceCore
import FinanceUI
import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @State var showOpeningBalanceSheet = false
    @Environment(AppNavigator.self) var navigator

    init(viewModel: DashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                netWorthHero(viewModel)

                if viewModel.effectiveTotals != nil {
                    metricsRow(viewModel)
                }

                recentActivityCard(viewModel)
            }
            .padding(AppSpacing.xxxl)
        }
        .background(AppColors.base)
        .task { await viewModel.load() }
        .sheet(isPresented: $showOpeningBalanceSheet) {
            OpeningBalanceSheet(viewModel: viewModel)
        }
    }
}

// Preview removed — inject DashboardViewModel from call site
