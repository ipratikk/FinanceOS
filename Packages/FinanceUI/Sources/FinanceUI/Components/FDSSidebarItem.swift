import FinanceCore
import SwiftUI

/// Sidebar navigation item with active state highlighting.
///
/// Active state: flat background, green accent icon.
/// Hover state: subtle background.
/// Default: secondary text, no fill.
public struct FDSSidebarItem: View {
    let title: String
    let symbol: String
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    @State private var isHovered = false

    public init(
        _ title: String,
        symbol: String,
        isSelected: Bool,
        badge: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.symbol = symbol
        self.isSelected = isSelected
        self.badge = badge
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(isSelected ? AppTypography.bodySmSemibold : AppTypography.bodySmMedium)
                    .foregroundColor(
                        isSelected
                            ? AppColors.accent
                            : AppColors.textSecondary
                    )
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 18)

                Text(title)
                    .font(isSelected ? AppTypography.bodySmSemibold : AppTypography.bodySm)
                    .foregroundColor(
                        isSelected || isHovered
                            ? AppColors.textPrimary
                            : AppColors.textSecondary
                    )

                Spacer(minLength: 4)

                if let badge {
                    Text(badge)
                        .font(AppTypography.maskedAccount.monospacedDigit())
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(AppColors.surface2)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(AppColors.surface.opacity(0.5))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isSelected)
    }
}

/// Sidebar section header — uppercase, tracked, tertiary text.
public struct FDSSidebarSectionHeader: View {
    let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10.5, weight: .semibold))
            .tracking(0.08)
            .foregroundColor(AppColors.textTertiary)
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
