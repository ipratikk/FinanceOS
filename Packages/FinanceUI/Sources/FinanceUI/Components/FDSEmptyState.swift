import FinanceCore
import SwiftUI

/// Shared empty state scaffold for list screens.
///
/// Replaces per-screen manual empty state VStacks.
public struct FDSEmptyState: View {
    /// SF Symbol name displayed at display-large size with hierarchical rendering.
    let symbol: String
    let title: String
    /// Secondary explanation text rendered in tertiary color below the title.
    let subtitle: String

    public init(symbol: String, title: String, subtitle: String) {
        self.symbol = symbol
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: symbol)
                .font(AppTypography.displayLargeLight)
                .foregroundStyle(AppColors.accentSlate.opacity(0.4))
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: AppSpacing.tight) {
                FDSLabel(title)
                    .font(AppTypography.bodyLg)
                    .foregroundColor(AppColors.Text.primary)
                FDSLabel(subtitle)
                    .font(AppTypography.captionLg)
                    .foregroundColor(AppColors.Text.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
