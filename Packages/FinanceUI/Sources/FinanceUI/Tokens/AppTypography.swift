import SwiftUI

/// Centralized typography system for FinanceOS.
/// All font usage must route through these semantic styles.
/// Do NOT use font(.system(size:)) directly.
public enum AppTypography {
    // MARK: - Display (Hero/Marketing)

    public static let displayLarge = Font.system(size: 32, weight: .bold, design: .default)
    public static let displayLargeLight = Font.system(size: 32, weight: .light, design: .default)
    public static let displaySmall = Font.system(size: 22, weight: .bold, design: .default)

    // MARK: - Headline (Section Headers, Titles)

    public static let headlineXL = Font.system(size: 24, weight: .bold, design: .default)
    public static let headlineLg = Font.system(size: 20, weight: .bold, design: .default)
    public static let headlineLgLight = Font.system(size: 20, weight: .light, design: .default)
    public static let headlineMd = Font.system(size: 18, weight: .semibold, design: .default)
    public static let headlineMdRegular = Font.system(size: 18, weight: .regular, design: .default)
    public static let headlineSm = Font.system(size: 16, weight: .semibold, design: .default)
    public static let headlineSmLight = Font.system(size: 16, weight: .light, design: .default)
    public static let subheadline = Font.system(size: 15, weight: .semibold, design: .default)

    // MARK: - Body (Primary Content)

    public static let bodyLg = Font.system(size: 16, weight: .regular, design: .default)
    public static let bodyMd = Font.system(size: 14, weight: .regular, design: .default)
    public static let bodyMdLight = Font.system(size: 14, weight: .light, design: .default)
    public static let bodySm = Font.system(size: 13, weight: .regular, design: .default)
    public static let bodySmSemibold = Font.system(size: 13, weight: .semibold, design: .default)
    public static let bodySmMedium = Font.system(size: 13, weight: .medium, design: .default)

    // MARK: - Caption (Secondary Content, Annotations)

    public static let captionLg = Font.system(size: 12, weight: .regular, design: .default)
    public static let captionLgSemibold = Font.system(size: 12, weight: .semibold, design: .default)
    public static let captionLgMedium = Font.system(size: 12, weight: .medium, design: .default)
    public static let captionSm = Font.system(size: 11, weight: .regular, design: .default)
    public static let captionSmSemibold = Font.system(size: 11, weight: .semibold, design: .default)
    public static let captionSmMedium = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Label (Small UI Elements, Labels)

    public static let label = Font.system(size: 10, weight: .regular, design: .default)
    public static let labelMedium = Font.system(size: 10, weight: .medium, design: .default)
    public static let labelSemibold = Font.system(size: 10, weight: .semibold, design: .default)

    // MARK: - Icon Text (Icon-adjacent text, small UI)

    public static let iconSm = Font.system(size: 9, weight: .semibold, design: .default)
    public static let iconMd = Font.system(size: 11, weight: .semibold, design: .default)

    // MARK: - Amount (Currency, Large Numbers)

    public static let amountLarge = Font.system(size: 36, weight: .bold, design: .default)
    public static let amountMedium = Font.system(size: 28, weight: .bold, design: .default)
    public static let amountSmall = Font.system(size: 28, weight: .bold, design: .default)

    // MARK: - Heading (Large Display)

    public static let headingXL = Font.system(size: 48, weight: .semibold, design: .default)
    public static let headingLg = Font.system(size: 44, weight: .bold, design: .default)
    public static let headingMd = Font.system(size: 40, weight: .semibold, design: .default)

    // MARK: - Monospace (Debug, Technical)

    public static let monospaceMd = Font.system(size: 13, weight: .regular, design: .monospaced)
}
