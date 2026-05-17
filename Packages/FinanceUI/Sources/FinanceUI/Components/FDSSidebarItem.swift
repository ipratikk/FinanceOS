import FinanceCore
import SwiftUI

/// Native macOS sidebar item. Thin, icon-first, hover-reactive.
///
/// Active state: floating glass capsule, soft glow, spatial.
/// No giant pills, no thick rectangles — feels like Arc/Raycast/Finder.
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
            HStack(spacing: AppSpacing.compact) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? AppColors.accent : .secondary)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 18)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer(minLength: 4)

                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, AppSpacing.compact)
            .padding(.vertical, 5)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                        }
                } else if isHovered {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

/// Sidebar section header — subtle, all-caps, low weight.
public struct FDSSidebarSectionHeader: View {
    let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, AppSpacing.compact)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.tight)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
