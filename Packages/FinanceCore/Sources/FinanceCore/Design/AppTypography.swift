import SwiftUI

// MARK: - Typography Tokens

//
// Display, Heading, and Amount tokens use explicit sizes — these are design-intent
// values that define the visual hierarchy of the app.
//
// Body and Caption tokens use macOS system text styles so they scale with
// Accessibility → Display → Text Size (Larger Text) where readability matters most.
//
// Use AppTypography.Dynamic for fully-adaptive text in accessibility-critical contexts.

public enum AppTypography {
    // MARK: - Display (Hero / Marketing)

    // Explicit sizes — these define the visual impact of hero sections.

    public static let displayLarge = Font.system(size: 34, weight: .bold)
    public static let displayLargeLight = Font.system(size: 34, weight: .light)
    public static let displaySmall = Font.system(size: 28, weight: .bold)

    // MARK: - Heading

    // Explicit sizes — section/screen titles set the information hierarchy.

    public static let headingXL = Font.system(size: 26, weight: .bold)
    public static let headingXLLight = Font.system(size: 26, weight: .light)
    public static let headingLg = Font.system(size: 22, weight: .bold)
    public static let headingLgLight = Font.system(size: 22, weight: .light)
    public static let headingMd = Font.system(size: 18, weight: .semibold)
    public static let headingMdRegular = Font.system(size: 18, weight: .regular)
    public static let headingSmall = Font.system(size: 16, weight: .semibold)
    public static let headlineSmLight = Font.system(size: 16, weight: .light)
    public static let subheadline = Font.system(size: 15, weight: .semibold)
    public static let headlineSm = Font.system(size: 16, weight: .semibold) // alias

    // MARK: - Screen Title

    public static let screenTitle = Font.system(size: 30, weight: .semibold)
    public static let titleSm = Font.system(size: 19, weight: .semibold)

    // MARK: - Body

    // System text styles — scale with Accessibility → Larger Text.

    public static let bodyLg = Font.headline.weight(.regular) // 13pt+, scales
    public static let bodyMd = Font.body.weight(.regular) // 13pt+, scales
    public static let bodyMdLight = Font.body.weight(.light)
    public static let bodyMdSemibold = Font.body.weight(.semibold)
    public static let bodySm = Font.body.weight(.regular)
    public static let bodySmMedium = Font.body.weight(.medium)
    public static let bodySmSemibold = Font.body.weight(.semibold)

    // MARK: - Label & Caption

    // System text styles — scale with Accessibility → Larger Text.

    public static let labelSemibold = Font.callout.weight(.semibold) // 12pt+
    public static let labelMedium = Font.callout.weight(.medium)
    public static let labelRegular = Font.callout.weight(.regular)
    public static let labelSmall = Font.subheadline.weight(.regular) // 11pt+
    public static let label = Font.subheadline.weight(.regular) // alias
    public static let captionLg = Font.subheadline.weight(.regular)
    public static let captionLgSemibold = Font.subheadline.weight(.semibold)
    public static let captionLgMedium = Font.subheadline.weight(.medium)
    public static let captionSm = Font.footnote.weight(.regular) // 10pt+
    public static let captionSmSemibold = Font.footnote.weight(.semibold)
    public static let captionSmMedium = Font.footnote.weight(.medium)

    // MARK: - Amount (Monospaced Currency)

    // Explicit sizes — currency display requires specific visual weight.

    public static let amountLarge = Font.system(size: 20, weight: .semibold, design: .monospaced)
    public static let amountMd = Font.system(size: 16, weight: .semibold, design: .monospaced)
    public static let amountSm = Font.system(size: 14, weight: .regular, design: .monospaced)
    public static let amountXs = Font.system(size: 12, weight: .regular, design: .monospaced)

    // MARK: - Icons

    public static let iconMd = Font.body
    public static let iconSm = Font.callout
    public static let iconXs = Font.subheadline

    // MARK: - Specialized

    /// 48pt — net flow hero amount on the Dashboard.
    public static let netHeroAmount = Font.system(size: 48, weight: .semibold)
    public static let maskedAccount = Font.system(size: 11, weight: .regular, design: .monospaced)

    // MARK: - Dynamic Type scale (fully adaptive — use in accessibility-critical contexts)

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

// MARK: - Font weight helpers (used by Dynamic enum)

private extension Font {
    func semibold() -> Font {
        weight(.semibold)
    }

    func bold() -> Font {
        weight(.bold)
    }
}
