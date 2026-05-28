import Charts
import FinanceCore
import FinanceUI
import SwiftUI

struct NetWorthDetailSheet: View {
    let viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            headerRow
            timeRangePicker
            CombinedFinancialChartView(
                netWorth: viewModel.netWorthTimeSeries,
                visibleDays: viewModel.selectedTimeRange.visibleDays
            )
            .id(viewModel.selectedTimeRange)
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            Spacer()
        }
        .padding(AppSpacing.xxxl)
        .frame(minWidth: 700, minHeight: 600)
        .background(AppColors.base)
    }

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                FDSLabel("NET WORTH")
                    .font(AppTypography.captionSmSemibold)
                    .tracking(0.8)
                    .foregroundStyle(AppColors.Text.tertiary)
                FDSLabel(FormatterCache.formatCurrency(viewModel.currentNetWorth, currencyCode: "INR"))
                    .font(AppTypography.displayLarge)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.Text.primary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppColors.Text.quaternary)
            }
            .buttonStyle(.plain)
        }
    }

    private var timeRangePicker: some View {
        Picker("Range", selection: Binding(
            get: { viewModel.selectedTimeRange },
            set: { range in Task { await viewModel.setTimeRange(range) } }
        )) {
            ForEach(TimeRange.allCases) { range in
                FDSLabel(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 300)
    }
}
