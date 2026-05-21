import SwiftUI

// MARK: - Typography Tokens

public enum AppTypography {
    // MARK: - Display (Hero / Marketing)

    public static let displayLarge = Font.system(size: 34, weight: .bold)
    public static let displayLargeLight = Font.system(size: 34, weight: .light)
    public static let displaySmall = Font.system(size: 22, weight: .bold)

    // MARK: - Heading

    public static let headingXL = Font.system(size: 24, weight: .bold)
    public static let headingXLLight = Font.system(size: 24, weight: .light)
    public static let headingLg = Font.system(size: 20, weight: .bold)
    public static let headingLgLight = Font.system(size: 20, weight: .light)
    public static let headingMd = Font.system(size: 18, weight: .semibold)
    public static let headingMdRegular = Font.system(size: 18, weight: .regular)
    public static let headingSmall = Font.system(size: 16, weight: .semibold)
    public static let headlineSmLight = Font.system(size: 16, weight: .light)
    public static let subheadline = Font.system(size: 15, weight: .semibold)

    public static let headlineSm = Font.system(size: 16, weight: .semibold) // alias — prefer headingSmall

    // MARK: - Body

    public static let bodyLg = Font.system(size: 16, weight: .regular)
    public static let bodyMd = Font.system(size: 14, weight: .regular)
    public static let bodyMdLight = Font.system(size: 14, weight: .light)
    public static let bodyMdSemibold = Font.system(size: 14, weight: .semibold)
    public static let bodySm = Font.system(size: 13, weight: .regular)
    public static let bodySmMedium = Font.system(size: 13, weight: .medium)
    public static let bodySmSemibold = Font.system(size: 13, weight: .semibold)

    // MARK: - Label & Caption

    public static let labelSemibold = Font.system(size: 13, weight: .semibold)
    public static let labelMedium = Font.system(size: 13, weight: .medium)
    public static let labelRegular = Font.system(size: 13, weight: .regular)
    public static let labelSmall = Font.system(size: 12, weight: .regular)
    public static let captionLg = Font.system(size: 12, weight: .regular)
    public static let captionLgSemibold = Font.system(size: 12, weight: .semibold)
    public static let captionLgMedium = Font.system(size: 12, weight: .medium)
    public static let captionSm = Font.system(size: 11, weight: .regular)
    public static let captionSmSemibold = Font.system(size: 11, weight: .semibold)
    public static let captionSmMedium = Font.system(size: 11, weight: .medium)

    public static let label = Font.system(size: 12, weight: .regular) // alias — prefer labelSmall

    // MARK: - Amount (Monospaced Currency)

    public static let amountLarge = Font.system(size: 20, weight: .semibold, design: .monospaced)
    public static let amountMd = Font.system(size: 16, weight: .semibold, design: .monospaced)
    public static let amountSm = Font.system(size: 14, weight: .regular, design: .monospaced)
    public static let amountXs = Font.system(size: 12, weight: .regular, design: .monospaced)

    // MARK: - Icons (SF Symbol sizing)

    public static let iconMd = Font.system(size: 16)
    public static let iconSm = Font.system(size: 14)
    public static let iconXs = Font.system(size: 12)

    // MARK: - Screen & Specialized

    public static let screenTitle = Font.system(size: 30, weight: .semibold)
    public static let titleSm = Font.system(size: 19, weight: .semibold)
    public static let netHeroAmount: Font = .system(size: 48, weight: .semibold)
    public static let maskedAccount: Font = .system(size: 11, weight: .regular, design: .monospaced)

    // MARK: - Dynamic Type scale (scales with macOS Accessibility Text Size)

    //
    // Use these for user-facing content where accessibility scaling is critical.
    // They correspond to the fixed-size tokens above but respond to Larger Text.

    public enum Dynamic {
        public static let display: Font = .largeTitle.bold()
        public static let title: Font = .title.bold()
        public static let title2: Font = .title2.semibold()
        public static let title3: Font = .title3.semibold()
        public static let headline: Font = .headline
        public static let body: Font = .body
        public static let callout: Font = .callout
        public static let subheadline: Font = .subheadline
        public static let footnote: Font = .footnote
        public static let caption: Font = .caption
        public static let caption2: Font = .caption2
    }
}

// MARK: - Font.semibold / Font.bold convenience

private extension Font {
    func semibold() -> Font {
        weight(.semibold)
    }

    func bold() -> Font {
        weight(.bold)
    }
}
