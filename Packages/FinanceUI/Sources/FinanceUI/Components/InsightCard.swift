import FinanceCore
import SwiftUI

/// Analytics insight card with a headline metric above a 120pt chart slot.
///
/// Shows `title` (caption) and `value` (displayLarge), then renders arbitrary content below.
/// Styled with `cardStyle()` — use `FDSMetricTile` for a non-chart metric display.
public struct InsightCard<Content: View>: View {
    let title: String
    let value: String
    let content: Content

    public init(_ title: String, value: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.value = value
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                FDSLabel(title)
                    .font(AppTypography.captionLg).foregroundColor(AppColors.Text.tertiary)

                FDSLabel(value)
                    .font(AppTypography.displayLarge)
                    .foregroundColor(AppColors.Text.primary)
            }

            content
                .frame(height: 120)
        }
        .cardStyle()
    }
}

#Preview {
    InsightCard("Monthly Spending", value: "₹1,24,500") {
        VStack(alignment: .center) {
            FDSLabel("Chart placeholder")
                .foregroundColor(AppColors.textTertiary)
        }
    }
    .padding(AppSpacing.lg)
    .background(AppColors.base)
}
