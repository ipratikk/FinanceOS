import FinanceCore
import SwiftUI

/// Period-over-period delta for `MetricCard`. Positive `change` = green up-arrow.
public struct MetricCardDelta {
    /// Percentage change (e.g. 12 = +12%). Sign determines color and arrow direction.
    public let change: Double
    /// Display label for the comparison period (e.g. "last month").
    public let period: String

    public init(change: Double, period: String) {
        self.change = change
        self.period = period
    }

    var isPositive: Bool {
        change >= 0
    }

    var text: String {
        String(format: "%+.0f%%", change)
    }
}

/// Large-format metric card with label, display-scale value, optional delta, and SF symbol.
///
/// Prefer `FDSMetricTile` for compact inline metrics. `MetricCard` is for
/// primary analytics summary positions where visual weight matters.
public struct MetricCard: View {
    let label: String
    let value: String
    let delta: MetricCardDelta?
    let icon: String?

    public typealias Delta = MetricCardDelta

    public init(_ label: String, value: String, delta: MetricCardDelta? = nil, icon: String? = nil) {
        self.label = label
        self.value = value
        self.delta = delta
        self.icon = icon
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(AppTypography.headlineSm)
                        .foregroundColor(AppColors.textTertiary)
                }
                FDSLabel(label)
                    .font(AppTypography.headingMd).foregroundColor(AppColors.Text.primary)
                Spacer()
            }

            FDSLabel(value)
                .font(AppTypography.displayLarge)
                .foregroundColor(AppColors.Text.primary)

            if let delta {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: delta.isPositive ? "triangle.fill" : "triangle.fill")
                        .font(AppTypography.captionSmSemibold)
                        .rotationEffect(.degrees(delta.isPositive ? 0 : 180))
                        .foregroundColor(delta.isPositive ? AppColors.credit : AppColors.debit)

                    FDSLabel(delta.text)
                        .font(AppTypography.captionLg).foregroundColor(AppColors.Text.tertiary)
                        .foregroundColor(delta.isPositive ? AppColors.credit : AppColors.debit)

                    FDSLabel("vs \(delta.period)")
                        .font(AppTypography.captionLg).foregroundColor(AppColors.Text.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        MetricCard(
            "Total Debits",
            value: "₹1,24,500",
            delta: .init(change: 12, period: "last month"),
            icon: "arrow.down.circle.fill"
        )
        MetricCard(
            "Total Credits",
            value: "₹85,000",
            delta: .init(change: -5, period: "last month"),
            icon: "arrow.up.circle.fill"
        )
    }
    .padding(AppSpacing.lg)
    .background(AppColors.base)
}
