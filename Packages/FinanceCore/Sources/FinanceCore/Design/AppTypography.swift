import SwiftUI

// MARK: - Typography Enum (Static Font Properties)

public enum AppTypography {
    // MARK: - Display (Hero/Marketing)

    public static let displayLarge = Font.system(size: 34, weight: .bold, design: .default)
    public static let displayLargeLight = Font.system(size: 34, weight: .light, design: .default)
    public static let displaySmall = Font.system(size: 22, weight: .bold, design: .default)

    // MARK: - Headline (Section Headers, Titles)

    public static let headlineXL = Font.system(size: 24, weight: .bold, design: .default)
    public static let headingXL = Font.system(size: 24, weight: .bold, design: .default)
    public static let headingXLLight = Font.system(size: 24, weight: .light, design: .default)
    public static let headlineLg = Font.system(size: 20, weight: .bold, design: .default)
    public static let headingLg = Font.system(size: 20, weight: .bold, design: .default)
    public static let headlineLgLight = Font.system(size: 20, weight: .light, design: .default)
    public static let headlineMd = Font.system(size: 18, weight: .semibold, design: .default)
    public static let headingMd = Font.system(size: 18, weight: .semibold, design: .default)
    public static let headlineMdRegular = Font.system(size: 18, weight: .regular, design: .default)
    public static let headlineSm = Font.system(size: 16, weight: .semibold, design: .default)
    public static let headingSmall = Font.system(size: 16, weight: .semibold, design: .default)
    public static let headlineSmLight = Font.system(size: 16, weight: .light, design: .default)
    public static let subheadline = Font.system(size: 15, weight: .semibold, design: .default)

    // MARK: - Body (Primary Content)

    public static let bodyLg = Font.system(size: 16, weight: .regular, design: .default)
    public static let bodyMd = Font.system(size: 14, weight: .regular, design: .default)
    public static let bodyMdLight = Font.system(size: 14, weight: .light, design: .default)
    public static let bodyMdSemibold = Font.system(size: 14, weight: .semibold, design: .default)
    public static let bodySm = Font.system(size: 13, weight: .regular, design: .default)
    public static let bodySmMedium = Font.system(size: 13, weight: .medium, design: .default)
    public static let bodySmSemibold = Font.system(size: 13, weight: .semibold, design: .default)

    // MARK: - Label & Caption

    public static let labelSemibold = Font.system(size: 13, weight: .semibold, design: .default)
    public static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)
    public static let labelRegular = Font.system(size: 13, weight: .regular, design: .default)
    public static let label = Font.system(size: 12, weight: .regular, design: .default)
    public static let labelSmall = Font.system(size: 12, weight: .regular, design: .default)

    public static let captionLg = Font.system(size: 12, weight: .regular, design: .default)
    public static let captionLgSemibold = Font.system(size: 12, weight: .semibold, design: .default)
    public static let captionLgMedium = Font.system(size: 12, weight: .medium, design: .default)
    public static let captionSm = Font.system(size: 11, weight: .regular, design: .default)
    public static let captionSmSemibold = Font.system(size: 11, weight: .semibold, design: .default)
    public static let captionSmMedium = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Amount (Monospaced Currency)

    public static let amountLarge = Font.system(size: 20, weight: .semibold, design: .monospaced)
    public static let amountMedium = Font.system(size: 16, weight: .semibold, design: .monospaced)
    public static let amountMd = Font.system(size: 16, weight: .semibold, design: .monospaced)
    public static let amountSm = Font.system(size: 14, weight: .regular, design: .monospaced)
    public static let amountXs = Font.system(size: 12, weight: .regular, design: .monospaced)

    // MARK: - Icons (Font sizing for SF Symbols)

    public static let iconMd = Font.system(size: 16)
    public static let iconSm = Font.system(size: 14)
    public static let iconXs = Font.system(size: 12)

    // MARK: - Specialized

    public static let netHeroAmount: Font = .system(size: 48, weight: .semibold)
    public static let maskedAccount: Font = .system(size: 10, weight: .regular, design: .monospaced)
}

// MARK: - View Extension Modifiers

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

    func headingSmall() -> some View {
        font(.system(size: 16, weight: .semibold, design: .default))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(1.4)
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

    func monoAmountDebit() -> some View {
        font(.system(size: 14, weight: .semibold, design: .monospaced))
            .foregroundColor(AppColors.debit)
            .lineSpacing(0)
    }

    func monoAmountCredit() -> some View {
        font(.system(size: 14, weight: .semibold, design: .monospaced))
            .foregroundColor(AppColors.credit)
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
