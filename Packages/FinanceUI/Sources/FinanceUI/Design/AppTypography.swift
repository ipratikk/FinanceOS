import SwiftUI

// MARK: - Typography Tokens

//
// All tokens use explicit sizes tuned for a spacious, readable finance app on macOS.
// Sizes are larger than Apple's default system text styles to give the UI breathing room.
//
// Use AppTypography.Dynamic for accessibility-critical contexts that must scale
// with macOS Accessibility → Display → Text Size (Larger Text).

/// Design-token namespace for all font styles in FinanceOS.
/// Fixed-size tokens give consistent visual hierarchy; use `AppTypography.Dynamic` where the system text size setting
/// must be respected (e.g. primary content, form labels).
public enum AppTypography {
    // MARK: - Style (use with .fdsFont() for screen-adaptive scaling)

    public enum Style: CaseIterable {
        case displayLarge, displayLargeLight, displaySmall
        case headingXL, headingXLLight, headingLg, headingLgLight
        case headingMd, headingMdRegular, headingSmall, headlineSmLight
        case subheadline, screenTitle, titleSm
        case bodyLg, bodyMd, bodyMdLight, bodyMdSemibold
        case bodySm, bodySmMedium, bodySmSemibold
        case labelSemibold, labelMedium, labelRegular, labelSmall
        case captionLg, captionLgSemibold, captionLgMedium
        case captionSm, captionSmSemibold, captionSmMedium
        case amountLarge, amountMd, amountSm, amountXs
        case iconMd, iconSm, iconXs
        case netHeroAmount, maskedAccount

        public var baseSize: CGFloat {
            switch self {
            case .displayLarge, .displayLargeLight: return 36
            case .displaySmall: return 28
            case .headingXL, .headingXLLight: return 28
            case .headingLg, .headingLgLight: return 24
            case .headingMd, .headingMdRegular: return 20
            case .headingSmall, .headlineSmLight: return 17
            case .subheadline: return 16
            case .screenTitle: return 32
            case .titleSm: return 20
            case .bodyLg: return 16
            case .bodyMd, .bodyMdLight, .bodyMdSemibold: return 15
            case .bodySm, .bodySmMedium, .bodySmSemibold: return 14
            case .labelSemibold, .labelMedium, .labelRegular: return 14
            case .labelSmall: return 13
            case .captionLg, .captionLgSemibold, .captionLgMedium: return 13
            case .captionSm, .captionSmSemibold, .captionSmMedium: return 12
            case .amountLarge: return 22
            case .amountMd: return 18
            case .amountSm: return 15
            case .amountXs: return 13
            case .iconMd: return 17
            case .iconSm: return 15
            case .iconXs: return 13
            case .netHeroAmount: return 52
            case .maskedAccount: return 12
            }
        }

        public var weight: Font.Weight {
            switch self {
            case .displayLargeLight, .headingXLLight, .headingLgLight, .headlineSmLight, .bodyMdLight:
                return .light
            case .displayLarge, .displaySmall, .headingXL, .headingLg, .screenTitle, .netHeroAmount:
                return .bold
            case .headingMd, .headingSmall, .subheadline, .titleSm,
                 .bodyMdSemibold, .bodySmSemibold, .labelSemibold,
                 .captionLgSemibold, .captionSmSemibold, .amountLarge, .amountMd:
                return .semibold
            case .bodySmMedium, .labelMedium, .captionLgMedium, .captionSmMedium:
                return .medium
            default:
                return .regular
            }
        }

        public var design: Font.Design {
            switch self {
            case .amountLarge, .amountMd, .amountSm, .amountXs, .maskedAccount:
                return .monospaced
            default:
                return .default
            }
        }

        public func font(scale: CGFloat = 1.0) -> Font {
            Font.system(size: baseSize * scale, weight: weight, design: design)
        }
    }

    // MARK: - Display (Hero / Marketing)

    /// 36pt bold — hero numbers on the dashboard (net worth, total spend).
    public static let displayLarge = Font.system(size: 36, weight: .bold)
    /// 36pt light — large decorative headers where weight contrast is desired.
    public static let displayLargeLight = Font.system(size: 36, weight: .light)
    /// 28pt bold — section hero amounts and prominent metric labels.
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

    /// Monospaced fonts keep currency digits aligned in list columns regardless of digit width.
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

    /// Fonts that scale with macOS Accessibility → Display → Text Size (Larger Text).
    /// Use for body copy, form labels, and any text that must remain readable at system-enlarged sizes.
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
