import FinanceCore
import SwiftUI

/// Standard list row component for all lists (accounts, cards, banks, etc.).
/// Centralizes row styling, spacing, and hit target enforcement.
public struct FDSListRow<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let icon: Image?
    let trailing: Trailing
    let isSelected: Bool
    let onTap: (() -> Void)?

    public init(
        title: String,
        subtitle: String? = nil,
        icon: Image? = nil,
        isSelected: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isSelected = isSelected
        self.onTap = onTap
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let icon {
                icon
                    .frame(width: AppSpacing.xxl, height: AppSpacing.xxl)
                    .foregroundColor(AppColors.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                FDSLabel(title)
                    .font(AppTypography.bodyMdSemibold)
                    .foregroundColor(DesignTokens.Text.primary)

                if let subtitle {
                    FDSLabel(subtitle)
                        .font(AppTypography.captionLg)
                        .foregroundColor(DesignTokens.Text.secondary)
                }
            }

            Spacer()

            trailing
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface2)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .strokeBorder(AppColors.accent.opacity(isSelected ? 0.2 : 0.1), lineWidth: 0.5)
        )
        .cornerRadius(AppRadius.sm)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap ?? {})
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(subtitle != nil ? "\(title), \(subtitle ?? "")" : title)
    }
}

// MARK: - Convenience Initializer (No Trailing Content)

public extension FDSListRow where Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        icon: Image? = nil,
        isSelected: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.init(title: title, subtitle: subtitle, icon: icon, isSelected: isSelected, onTap: onTap) {
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.sm) {
        FDSListRow(
            title: "Chase Checking",
            subtitle: "****1234",
            icon: Image(systemName: "building.2.fill")
        ) {
            FDSLabel("$5,234.50")
                .font(AppTypography.bodyMdSemibold)
                .foregroundColor(DesignTokens.Text.primary)
        }

        FDSListRow(
            title: "AMEX Credit Card",
            subtitle: "****5678",
            icon: Image(systemName: "creditcard.fill")
        ) {
            VStack(alignment: .trailing, spacing: 2) {
                FDSLabel("$2,100.00")
                    .font(AppTypography.captionLgSemibold)
                    .foregroundColor(.blue)
                FDSLabel("Due Apr 15")
                    .font(AppTypography.maskedAccount)
                    .foregroundColor(DesignTokens.Text.secondary)
            }
        }
    }
    .padding()
}
