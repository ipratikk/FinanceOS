import SwiftUI

public struct FBadge: View {
    let text: String
    let color: BadgeColor
    let icon: String?

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
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 12, weight: .medium))
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
