import SwiftUI

extension View {
    public func displayLarge() -> some View {
        self
            .font(.system(size: 34, weight: .bold, design: .default))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(2)
    }

    public func displayMedium() -> some View {
        self
            .font(.system(size: 28, weight: .bold, design: .default))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(2)
    }

    public func headingLarge() -> some View {
        self
            .font(.system(size: 22, weight: .bold, design: .default))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(1.5)
    }

    public func headingMedium() -> some View {
        self
            .font(.system(size: 18, weight: .semibold, design: .default))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(1.5)
    }

    public func bodyLarge() -> some View {
        self
            .font(.system(size: 15, weight: .medium, design: .default))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(1.2)
    }

    public func bodyMedium() -> some View {
        self
            .font(.system(size: 14, weight: .regular, design: .default))
            .foregroundColor(AppColors.textSecondary)
            .lineSpacing(1.2)
    }

    public func labelSmall() -> some View {
        self
            .font(.system(size: 12, weight: .regular, design: .default))
            .foregroundColor(AppColors.textTertiary)
            .lineSpacing(1)
    }

    public func monoAmount() -> some View {
        self
            .font(.system(size: 14, weight: .semibold, design: .monospaced))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(0)
    }

    public func monoAmountSmall() -> some View {
        self
            .font(.system(size: 12, weight: .regular, design: .monospaced))
            .foregroundColor(AppColors.textSecondary)
            .lineSpacing(0)
    }

    public func captionLarge() -> some View {
        self
            .font(.system(size: 13, weight: .semibold, design: .default))
            .foregroundColor(AppColors.textSecondary)
            .lineSpacing(1)
    }

    public func caption() -> some View {
        self
            .font(.system(size: 12, weight: .regular, design: .default))
            .foregroundColor(AppColors.textTertiary)
            .lineSpacing(1)
    }
}
