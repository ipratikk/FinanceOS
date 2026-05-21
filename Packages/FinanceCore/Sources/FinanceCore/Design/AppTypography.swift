import SwiftUI

// MARK: - Typography Tokens

//
// All tokens use explicit sizes tuned for a spacious, readable finance app on macOS.
// Sizes are larger than Apple's default system text styles to give the UI breathing room.
//
// Use AppTypography.Dynamic for accessibility-critical contexts that must scale
// with macOS Accessibility → Display → Text Size (Larger Text).

public enum AppTypography {
    // MARK: - Display (Hero / Marketing)

    public static let displayLarge = Font.system(size: 36, weight: .bold)
    public static let displayLargeLight = Font.system(size: 36, weight: .light)
    public static let displaySmall = Font.system(size: 28, weight: .bold)

    // MARK: - Heading

    public static let headingXL = Font.system(size: 28, weight: .bold)
    public static let headingXLLight = Font.system(size: 28, weight: .light)
    public static let headingLg = Font.system(size: 24, weight: .bold)
    public static let headingLgLight = Font.system(size: 24, weight: .light)
    public static let headingMd = Font.system(size: 20, weight: .semibold)
    public static let headingMdRegular = Font.system(size: 20, weight: .regular)
    public static let headingSmall = Font.system(size: 17, weight: .semibold)
    public static let headlineSmLight = Font.system(size: 17, weight: .light)
    public static let subheadline = Font.system(size: 16, weight: .semibold)
    public static let headlineSm = Font.system(size: 17, weight: .semibold) // alias

    // MARK: - Screen Title

    public static let screenTitle = Font.system(size: 32, weight: .semibold)
    public static let titleSm = Font.system(size: 20, weight: .semibold)

    // MARK: - Body

    public static let bodyLg = Font.system(size: 16, weight: .regular)
    public static let bodyMd = Font.system(size: 15, weight: .regular)
    public static let bodyMdLight = Font.system(size: 15, weight: .light)
    public static let bodyMdSemibold = Font.system(size: 15, weight: .semibold)
    public static let bodySm = Font.system(size: 14, weight: .regular)
    public static let bodySmMedium = Font.system(size: 14, weight: .medium)
    public static let bodySmSemibold = Font.system(size: 14, weight: .semibold)

    // MARK: - Label & Caption

    public static let labelSemibold = Font.system(size: 14, weight: .semibold)
    public static let labelMedium = Font.system(size: 14, weight: .medium)
    public static let labelRegular = Font.system(size: 14, weight: .regular)
    public static let labelSmall = Font.system(size: 13, weight: .regular)
    public static let label = Font.system(size: 13, weight: .regular) // alias
    public static let captionLg = Font.system(size: 13, weight: .regular)
    public static let captionLgSemibold = Font.system(size: 13, weight: .semibold)
    public static let captionLgMedium = Font.system(size: 13, weight: .medium)
    public static let captionSm = Font.system(size: 12, weight: .regular)
    public static let captionSmSemibold = Font.system(size: 12, weight: .semibold)
    public static let captionSmMedium = Font.system(size: 12, weight: .medium)

    // MARK: - Amount (Monospaced Currency)

    public static let amountLarge = Font.system(size: 22, weight: .semibold, design: .monospaced)
    public static let amountMd = Font.system(size: 18, weight: .semibold, design: .monospaced)
    public static let amountSm = Font.system(size: 15, weight: .regular, design: .monospaced)
    public static let amountXs = Font.system(size: 13, weight: .regular, design: .monospaced)

    // MARK: - Icons

    public static let iconMd = Font.system(size: 17)
    public static let iconSm = Font.system(size: 15)
    public static let iconXs = Font.system(size: 13)

    // MARK: - Specialized

    /// 52pt — net flow hero amount on the Dashboard.
    public static let netHeroAmount = Font.system(size: 52, weight: .semibold)
    public static let maskedAccount = Font.system(size: 12, weight: .regular, design: .monospaced)

    // MARK: - Dynamic Type (fully adaptive, use in accessibility-critical contexts)

    public enum Dynamic {
        public static let display: Font = .largeTitle.bold()
        public static let title: Font = .title.bold()
        public static let title2: Font = .title2.weight(.semibold)
        public static let title3: Font = .title3.weight(.semibold)
        public static let headline: Font = .headline
        public static let body: Font = .body
        public static let callout: Font = .callout
        public static let subheadline: Font = .subheadline
        public static let footnote: Font = .footnote
        public static let caption: Font = .caption
        public static let caption2: Font = .caption2
    }
}

private extension Font {
    func semibold() -> Font {
        weight(.semibold)
    }

    func bold() -> Font {
        weight(.bold)
    }
}
