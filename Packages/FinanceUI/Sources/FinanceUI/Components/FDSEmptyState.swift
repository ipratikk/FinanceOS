import FinanceCore
import SwiftUI

/// Shared empty state scaffold for list screens.
///
/// Replaces per-screen manual empty state VStacks.
public struct FDSEmptyState: View {
    let symbol: String
    let title: String
    let subtitle: String

    public init(symbol: String, title: String, subtitle: String) {
        self.symbol = symbol
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: symbol)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AppColors.accentSlate.opacity(0.4))
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: AppSpacing.tight) {
                Text(title)
                    .bodyLarge()
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
