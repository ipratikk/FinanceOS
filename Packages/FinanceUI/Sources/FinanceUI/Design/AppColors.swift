import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Central design-token namespace for all colors used in FinanceOS.
/// Always consume a named token rather than constructing `Color` values inline in Views.
public enum AppColors {
    // MARK: - Adaptive Helper

    private struct RGB {
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        init(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) {
            self.r = r; self.g = g; self.b = b
        }
    }

    private static func adaptive(dark: RGB, light: RGB) -> Color {
        #if canImport(AppKit)
        Color(NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let rgb = isDark ? dark : light
            return NSColor(calibratedRed: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
        })
        #elseif canImport(UIKit)
        Color(UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
        })
        #else
        Color(red: dark.r, green: dark.g, blue: dark.b)
        #endif
    }

    // MARK: - Backgrounds

    /// App wallpaper canvas. Dark: #0f0f12 · Light: #F5F5F7
    public static let base = adaptive(
        dark: RGB(0.060, 0.060, 0.070),
        light: RGB(0.961, 0.961, 0.969)
    )

    /// macOS system surfaces — adaptive via NSColor semantics.
    public static let surface = Color(NSColor.controlBackgroundColor)
    public static let surface2 = Color(NSColor.windowBackgroundColor)
    public static let surface3 = Color(NSColor.textBackgroundColor)

    // MARK: - Borders & Dividers (legacy — prefer Border.* enum)

    public static let border = Color.primary.opacity(0.08)
    public static let borderAccent = Color.primary.opacity(0.12)
    public static let glass = Color.primary.opacity(0.02)

    // MARK: - Primary Accents

    /// #30D158 — Emerald green; primary brand accent.
    public static let accentGreen = Color(red: 0.188, green: 0.827, blue: 0.345)
    /// #FF9F0A — Gold orange; secondary accent.
    public static let accentOrange = Color(red: 1.0, green: 0.62, blue: 0.04)
    /// #0A84FF — Cobalt blue; info states.
    public static let accentBlue = Color(red: 0.039, green: 0.518, blue: 1.0)
    /// #BF5AF2 — Plum purple; investment/crypto.
    public static let accentPurple = Color(red: 0.749, green: 0.345, blue: 0.949)
    /// #8E8E93 — Muted gray; disabled non-text.
    public static let accentMuted = Color(red: 0.557, green: 0.557, blue: 0.576)

    public static let accentGold = accentOrange
    public static let accentSlate = accentBlue
    public static let accentIce = accentBlue

    // MARK: - Semantic Colors

    public static let accent = accentGreen
    public static let success = Color(red: 0.188, green: 0.827, blue: 0.345)
    public static let danger = Color(red: 1.0, green: 0.231, blue: 0.188)
    public static let info = accentBlue
    public static let warning = Color(red: 1.0, green: 0.584, blue: 0)
    public static let credit = success
    public static let debit = danger
    public static let purple = accentPurple
    public static let clear = Color.clear

    // MARK: - Legacy flat text tokens (prefer Text.* in new code)

    public static let textPrimary = Text.primary
    public static let textSecondary = Text.secondary
    public static let textTertiary = Text.tertiary
    public static let textDisabled = Text.disabled

    // MARK: - Semantic Text Hierarchy (adaptive)

    public enum Text {
        /// Dark: #F1F3F6 · Light: #1C1C1E
        public static let primary = adaptive(
            dark: RGB(0.945, 0.953, 0.965),
            light: RGB(0.110, 0.110, 0.118)
        )
        /// Dark: #BDC2CC · Light: #3C3C43
        public static let secondary = adaptive(
            dark: RGB(0.741, 0.761, 0.800),
            light: RGB(0.235, 0.235, 0.263)
        )
        /// Dark: #858A94 · Light: #636366
        public static let tertiary = adaptive(
            dark: RGB(0.518, 0.541, 0.580),
            light: RGB(0.388, 0.388, 0.400)
        )
        /// Dark: #8F94A0 · Light: #6C6C70
        public static let tertiaryElevated = adaptive(
            dark: RGB(0.560, 0.580, 0.620),
            light: RGB(0.424, 0.424, 0.439)
        )
        /// Dark: #636874 · Light: #8E8E93 — decorative only
        public static let quaternary = adaptive(
            dark: RGB(0.390, 0.410, 0.450),
            light: RGB(0.557, 0.557, 0.576)
        )
        /// Dark: #52525B · Light: #AEAEB2
        public static let disabled = adaptive(
            dark: RGB(0.322, 0.322, 0.361),
            light: RGB(0.682, 0.682, 0.698)
        )
    }

    // MARK: - Fill Hierarchy (adaptive via Color.primary)

    public enum Fill {
        public static let primary = Color.primary.opacity(0.05)
        public static let secondary = Color.primary.opacity(0.08)
        public static let tertiary = Color.primary.opacity(0.11)
        public static let quaternary = Color.primary.opacity(0.15)
    }

    // MARK: - Glass Surfaces (adaptive via Color.primary)

    public enum Glass {
        public static let thinTint = Color.primary.opacity(0.04)
        public static let surface = Color.primary.opacity(0.06)
        public static let midTint = Color.primary.opacity(0.08)
        public static let thickTint = Color.primary.opacity(0.10)
        public static let highlight = Color.primary.opacity(0.12)
        public static let chrome = Color(red: 20 / 255, green: 22 / 255, blue: 30 / 255).opacity(0.65)
        public static let inputWell = AppColors.base.opacity(0.25)

        public static var gleamBorder: LinearGradient {
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.16),
                    Color.primary.opacity(0.06),
                    .clear,
                    AppColors.base.opacity(0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Border Hierarchy (adaptive via Color.primary)

    public enum Border {
        public static let subtle = Color.primary.opacity(0.06)
        public static let strong = Color.primary.opacity(0.10)
        public static let input = Color.primary.opacity(0.25)
        public static let focus = AppColors.accentGreen.opacity(0.70)
    }

    // MARK: - Opacity Scale

    public enum Opacity {
        public static let low: Double = 0.20
        public static let medium: Double = 0.30
        public static let muted: Double = 0.40
        public static let high: Double = 0.50
        public static let strong: Double = 0.80
    }

    // MARK: - Apple System Colors

    public enum System {
        public static let red = Color(red: 1.00, green: 0.27, blue: 0.23)
        public static let orange = Color(red: 1.00, green: 0.62, blue: 0.04)
        public static let yellow = Color(red: 1.00, green: 0.84, blue: 0.04)
        public static let green = Color(red: 0.19, green: 0.82, blue: 0.35)
        public static let mint = Color(red: 0.40, green: 0.83, blue: 0.81)
        public static let teal = Color(red: 0.25, green: 0.78, blue: 0.88)
        public static let cyan = Color(red: 0.39, green: 0.82, blue: 1.00)
        public static let blue = Color(red: 0.04, green: 0.52, blue: 1.00)
        public static let indigo = Color(red: 0.37, green: 0.36, blue: 0.90)
        public static let purple = Color(red: 0.75, green: 0.35, blue: 0.95)
        public static let pink = Color(red: 1.00, green: 0.22, blue: 0.37)
        public static let gray = Color(red: 0.60, green: 0.60, blue: 0.62)
    }
}
