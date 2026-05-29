import FinanceCore
import SwiftUI

/// Information-dense metric tile. Replaces oversized MetricCard.
///
/// Layout:
/// ```
/// [symbol]  Label
///           ₹2,654.33
///           ▲ 12.5% vs last month
/// ```
public struct FDSMetricTile: View {
    let label: String
    let value: String
    /// Optional SF Symbol shown inline with the label at caption size.
    let symbol: String?
    let delta: Delta?
    /// When true, uses `displayLarge` for the value; when false, uses `displaySmall`.
    let prominent: Bool

    /// Period-over-period change data for the metric. Positive `value` renders green/up-arrow.
    public struct Delta {
        /// Percentage change (e.g. 12.5 = +12.5%). Negative values show down-arrow in red.
        public let value: Double
        /// Human-readable period label (e.g. "vs last month").
        public let period: String

        public init(value: Double, period: String) {
            self.value = value
            self.period = period
        }
    }

    public init(
        _ label: String,
        value: String,
        symbol: String? = nil,
        delta: Delta? = nil,
        prominent: Bool = false
    ) {
        self.label = label
        self.value = value
        self.symbol = symbol
        self.delta = delta
        self.prominent = prominent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            HStack(spacing: AppSpacing.compact) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(AppTypography.captionSmSemibold)
                        .foregroundStyle(.tertiary)
                        .frame(width: AppSpacing.md, height: AppSpacing.md)
                }
                FDSLabel(label.uppercased())
                    .font(AppTypography.captionSmSemibold)
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)
            }

            FDSLabel(value)
                .font(prominent ? AppTypography.displayLarge : AppTypography.displaySmall)
                .monospacedDigit()
                .foregroundStyle(AppColors.accentIce)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if let delta {
                HStack(spacing: 4) {
                    Image(systemName: delta.value >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(AppTypography.captionSmSemibold)
                    FDSLabel(String(format: "%.1f%% \(delta.period)", abs(delta.value)))
                        .font(AppTypography.captionSmMedium)
                }
                .foregroundStyle(delta.value >= 0 ? AppColors.credit : AppColors.debit)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
