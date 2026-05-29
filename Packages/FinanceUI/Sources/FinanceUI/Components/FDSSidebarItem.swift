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
    /// Optional count string shown at the trailing edge (e.g. "12" for 12 pending items).
    let badge: String?
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        Button(action: action, label: {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(isSelected ? AppTypography.bodySmSemibold : AppTypography.bodySmMedium)
                    .foregroundColor(isSelected ? AppColors.accent : AppColors.Text.secondary)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 18)

                FDSLabel(title)
                    .font(isSelected ? AppTypography.bodySmSemibold : AppTypography.bodySm)
                    .foregroundColor(isSelected || isHovered ? AppColors.Text.primary : AppColors.Text.secondary)

                Spacer(minLength: 4)

                if let badge {
                    FDSLabel(badge)
                        .font(AppTypography.maskedAccount.monospacedDigit())
                        .foregroundColor(AppColors.Text.quaternary)
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
        })
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .motionAnimation(AppAnimation.hover, value: isHovered)
        .motionAnimation(AppAnimation.selection, value: isSelected)
    }
}

/// Uppercase, letter-spaced section label for sidebar navigation groups.
///
/// Uses `captionSmSemibold` at 0.08 tracking in tertiary text. No interaction.
public struct FDSSidebarSectionHeader: View {
    let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        FDSLabel(title.uppercased())
            .font(AppTypography.captionSmSemibold)
            .tracking(0.08)
            .foregroundColor(AppColors.Text.tertiary)
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
