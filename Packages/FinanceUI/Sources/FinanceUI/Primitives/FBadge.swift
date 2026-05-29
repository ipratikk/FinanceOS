import FinanceCore
import SwiftUI

/// Compact status badge with optional SF Symbol icon and semantic color.
///
/// Renders as a capsule-style pill. Use for status labels (e.g. "Active", "Debit"),
/// card network tags, or any short categorical annotation.
public struct FBadge: View {
    let text: String
    let color: BadgeColor
    /// Optional SF Symbol name rendered before the text label.
    let icon: String?

    /// Pre-defined semantic color options with matching background/foreground pairs.
    public enum BadgeColor {
        case blue
        case green
        case red
        case amber
        case purple
        case gray

        var background: Color {
            switch self {
            case .blue: return AppColors.accent.opacity(0.15)
            case .green: return AppColors.credit.opacity(0.15)
            case .red: return AppColors.debit.opacity(0.15)
            case .amber: return AppColors.warning.opacity(0.15)
            case .purple: return AppColors.purple.opacity(0.15)
            case .gray: return AppColors.surface2.opacity(0.5)
            }
        }

        var foreground: Color {
            switch self {
            case .blue: return AppColors.accent
            case .green: return AppColors.credit
            case .red: return AppColors.debit
            case .amber: return AppColors.warning
            case .purple: return AppColors.purple
            case .gray: return AppColors.textSecondary
            }
        }
    }

    public init(_ text: String, color: BadgeColor = .gray, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            if let icon {
                Image(systemName: icon)
                    .font(AppTypography.captionSmSemibold)
            }
            FDSLabel(text)
                .font(AppTypography.captionLgMedium)
        }
        .foregroundColor(color.foreground)
        .padding(.vertical, AppSpacing.xxs)
        .padding(.horizontal, AppSpacing.sm)
        .background(color.background)
        .cornerRadius(AppRadius.sm)
    }
}

#Preview {
    HStack(spacing: AppSpacing.md) {
        FBadge("Active", color: .green, icon: "checkmark.circle.fill")
        FBadge("Debit", color: .red)
        FBadge("Credit", color: .green)
        FBadge("Warning", color: .amber)
        FBadge("Amex", color: .blue, icon: "creditcard.fill")
    }
    .padding()
    .background(AppColors.base)
}
