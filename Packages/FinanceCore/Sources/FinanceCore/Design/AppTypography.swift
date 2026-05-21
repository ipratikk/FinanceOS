import SwiftUI

// MARK: - Typography Tokens

//
// All tokens use system text styles so they scale automatically with
// macOS Accessibility → Display → Text Size (Larger Text).
//
// Weight is applied via .weight() on the text style font.
// Monospaced fonts use .monospaced() modifier on the scaled base.

public enum AppTypography {
    // MARK: - Display (Hero / Marketing)

    // largeTitle = 26pt base on macOS, scales up

    public static let displayLarge = Font.largeTitle.weight(.bold)
    public static let displayLargeLight = Font.largeTitle.weight(.light)
    public static let displaySmall = Font.title.weight(.bold)

    // MARK: - Heading

    // title = 22pt, title2 = 17pt, title3 = 15pt on macOS

    public static let headingXL = Font.title.weight(.bold)
    public static let headingXLLight = Font.title.weight(.light)
    public static let headingLg = Font.title2.weight(.bold)
    public static let headingLgLight = Font.title2.weight(.light)
    public static let headingMd = Font.title2.weight(.semibold)
    public static let headingMdRegular = Font.title2.weight(.regular)
    public static let headingSmall = Font.title3.weight(.semibold)
    public static let headlineSmLight = Font.title3.weight(.light)
    public static let subheadline = Font.title3.weight(.semibold)
    public static let headlineSm = Font.title3.weight(.semibold) // alias — prefer headingSmall

    // MARK: - Body

    // headline/body = 13pt, callout = 12pt on macOS

    public static let bodyLg = Font.headline.weight(.regular)
    public static let bodyMd = Font.body.weight(.regular)
    public static let bodyMdLight = Font.body.weight(.light)
    public static let bodyMdSemibold = Font.body.weight(.semibold)
    public static let bodySm = Font.callout.weight(.regular)
    public static let bodySmMedium = Font.callout.weight(.medium)
    public static let bodySmSemibold = Font.callout.weight(.semibold)

    // MARK: - Label & Caption

    // subheadline = 11pt, footnote = 10pt, caption = 10pt on macOS

    public static let labelSemibold = Font.callout.weight(.semibold)
    public static let labelMedium = Font.callout.weight(.medium)
    public static let labelRegular = Font.callout.weight(.regular)
    public static let labelSmall = Font.subheadline.weight(.regular)
    public static let label = Font.subheadline.weight(.regular) // alias — prefer labelSmall
    public static let captionLg = Font.subheadline.weight(.regular)
    public static let captionLgSemibold = Font.subheadline.weight(.semibold)
    public static let captionLgMedium = Font.subheadline.weight(.medium)
    public static let captionSm = Font.footnote.weight(.regular)
    public static let captionSmSemibold = Font.footnote.weight(.semibold)
    public static let captionSmMedium = Font.footnote.weight(.medium)

    // MARK: - Amount (Monospaced Currency)

    // Scaled from body/callout base, then monospaced

    public static let amountLarge = Font.title2.weight(.semibold).monospaced()
    public static let amountMd = Font.headline.weight(.semibold).monospaced()
    public static let amountSm = Font.body.weight(.regular).monospaced()
    public static let amountXs = Font.subheadline.weight(.regular).monospaced()

    // MARK: - Icons (SF Symbol sizing — uses body scale)

    public static let iconMd = Font.body
    public static let iconSm = Font.callout
    public static let iconXs = Font.subheadline

    // MARK: - Screen & Specialized

    public static let screenTitle = Font.largeTitle.weight(.semibold)
    public static let titleSm = Font.title3.weight(.semibold)
    public static let netHeroAmount = Font.largeTitle.weight(.semibold).monospaced()
    public static let maskedAccount = Font.footnote.weight(.regular).monospaced()
}
