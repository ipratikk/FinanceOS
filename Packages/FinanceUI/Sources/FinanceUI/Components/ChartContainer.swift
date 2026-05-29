import FinanceCore
import SwiftUI

/// Titled card wrapper for charts. Provides consistent padding and `cardStyle()` chrome.
///
/// Content is constrained to 200pt height — pass a Charts view or placeholder inside.
public struct ChartContainer<Content: View>: View {
    let title: String
    let content: Content

    public init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            FDSLabel(title)
                .font(AppTypography.headingMd)
                .foregroundColor(AppColors.Text.primary)

            content
                .frame(height: 200)
        }
        .cardStyle()
    }
}

#Preview {
    ChartContainer("Spending Trend") {
        VStack(alignment: .center) {
            FDSLabel("Chart goes here")
                .foregroundColor(AppColors.textTertiary)
        }
    }
    .padding(AppSpacing.lg)
    .background(AppColors.base)
}
