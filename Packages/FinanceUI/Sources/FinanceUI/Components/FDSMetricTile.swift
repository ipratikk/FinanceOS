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
    let symbol: String?
    let delta: Delta?
    let prominent: Bool

    public struct Delta {
        public let value: Double
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
                    .font(AppTypography.custom(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)
            }

            FDSLabel(value)
                .font(AppTypography.custom(size: prominent ? 32 : 22, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppColors.accentIce)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if let delta {
                HStack(spacing: 4) {
                    Image(systemName: delta.value >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(AppTypography.custom(size: 9, weight: .bold))
                    FDSLabel("\(abs(delta.value), specifier: "%.1f")% \(delta.period)")
                        .font(AppTypography.custom(size: 10, weight: .medium))
                }
                .foregroundStyle(delta.value >= 0 ? AppColors.credit : AppColors.debit)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
