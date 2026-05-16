import SwiftUI

public extension View {
    func displayLarge() -> some View {
        font(.system(size: 34, weight: .bold, design: .default))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(2)
    }

    func displayMedium() -> some View {
        font(.system(size: 28, weight: .bold, design: .default))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(2)
    }

    func headingLarge() -> some View {
        font(.system(size: 22, weight: .bold, design: .default))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(1.5)
    }

    func headingMedium() -> some View {
        font(.system(size: 18, weight: .semibold, design: .default))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(1.5)
    }

    func bodyLarge() -> some View {
        font(.system(size: 15, weight: .medium, design: .default))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(1.2)
    }

    func bodyMedium() -> some View {
        font(.system(size: 14, weight: .regular, design: .default))
            .foregroundColor(AppColors.textSecondary)
            .lineSpacing(1.2)
    }

    func labelSmall() -> some View {
        font(.system(size: 12, weight: .regular, design: .default))
            .foregroundColor(AppColors.textTertiary)
            .lineSpacing(1)
    }

    func monoAmount() -> some View {
        font(.system(size: 14, weight: .semibold, design: .monospaced))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(0)
    }

    func monoAmountSmall() -> some View {
        font(.system(size: 12, weight: .regular, design: .monospaced))
            .foregroundColor(AppColors.textSecondary)
            .lineSpacing(0)
    }

    func captionLarge() -> some View {
        font(.system(size: 13, weight: .semibold, design: .default))
            .foregroundColor(AppColors.textSecondary)
            .lineSpacing(1)
    }

    func caption() -> some View {
        font(.system(size: 12, weight: .regular, design: .default))
            .foregroundColor(AppColors.textTertiary)
            .lineSpacing(1)
    }
}
