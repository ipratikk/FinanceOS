import SwiftUI

public enum AppColors {
    // MARK: - Backgrounds

    public static let base = Color(red: 0.06, green: 0.06, blue: 0.07) // #0f0f12 — main background
    public static let surface = Color(red: 0.12, green: 0.12, blue: 0.13) // #1e1e21 — primary surface
    public static let surface2 = Color(red: 0.16, green: 0.16, blue: 0.17) // #292a2b — elevated surface
    public static let surface3 = Color(red: 0.20, green: 0.20, blue: 0.22) // #333537 — top elevation
    public static let elevated = surface2

    // MARK: - Borders & Dividers

    public static let border = textPrimary.opacity(0.08) // subtle border
    public static let borderAccent = textPrimary.opacity(0.12) // accent border
    public static let borderSubtle = textPrimary.opacity(0.05) // minimal separator

    // MARK: - Glass & Material overlays (deprecated — use border colors instead)

    public static let glass = textPrimary.opacity(0.02) // minimal tint
    public static let borderGlass = textPrimary.opacity(0.08) // flat border

    // MARK: - Primary Accents (Apple System Colors)

    public static let accentGreen = Color(red: 0.188, green: 0.827, blue: 0.345) // #30D158 — Emerald (primary)
    public static let accentOrange = Color(red: 1.0, green: 0.62, blue: 0.04) // #FF9F0A — Gold (secondary)
    public static let accentBlue = Color(red: 0.039, green: 0.518, blue: 1.0) // #0A84FF — Cobalt
    public static let accentPurple = Color(red: 0.749, green: 0.345, blue: 0.949) // #BF5AF2 — Plum
    public static let accentGold = accentOrange // Mapped for compatibility
    public static let accentSlate = accentBlue // Mapped for compatibility
    public static let accentIce = accentBlue // Mapped for compatibility
    public static let accentMuted = Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93 — muted gray

    // MARK: - Semantic Colors (Apple System)

    public static let accent = accentGreen // Default primary accent — emerald green
    public static let success = Color(red: 0.188, green: 0.827, blue: 0.345) // #30D158 — Apple Green
    public static let danger = Color(red: 1.0, green: 0.231, blue: 0.188) // #FF3B30 — Apple Red
    public static let info = accentBlue // Informational color
    public static let warning = Color(red: 1.0, green: 0.584, blue: 0) // #FF9500 — Apple Orange

    // MARK: - Legacy semantic colors (mapped for backwards compatibility)

    public static let credit = success // Positive transaction
    public static let debit = danger // Negative transaction
    public static let purple = accentPurple // Fallback color

    // MARK: - Deprecated neon colors (removed for classy aesthetic)

    public static let accentCyan = accentBlue // Replaced
    public static let accentBlueDeprecated = accentBlue // Replaced
    public static let accentPurpleDeprecated = accentPurple // Replaced
    public static let accentPink = danger // Replaced
    public static let accentLime = success // Replaced

    // MARK: - Text (Apple System)

    public static let textPrimary = Color.white // #FFFFFF
    public static let textSecondary = Color(red: 0.631, green: 0.631, blue: 0.651) // #A1A1A6
    public static let textTertiary = Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93
    public static let textDisabled = Color(red: 0.322, green: 0.322, blue: 0.361) // #52525B
    public static let clear = Color.clear

    // MARK: - Semantic Text Hierarchy

    public enum Text {
        /// #F1F3F6 — near-white, primary content
        public static let primary = Color(red: 0.945, green: 0.953, blue: 0.965)
        /// #BDC2CC — muted secondary content
        public static let secondary = Color(red: 0.741, green: 0.761, blue: 0.800)
        /// #858A94 — tertiary metadata (4.5:1 on base, 4.1:1 on surface2 — use tertiaryElevated on cards)
        public static let tertiary = Color(red: 0.518, green: 0.541, blue: 0.580)
        /// #8F94A0 — tertiary on elevated surfaces (4.8:1 on surface2, passes AA)
        public static let tertiaryElevated = Color(red: 0.56, green: 0.58, blue: 0.62)
        /// #636874 — decorative only: dots, separators, inactive indicators. NOT for text. (3.5:1 on base)
        public static let quaternary = Color(red: 0.39, green: 0.41, blue: 0.45)
    }

    // MARK: - Glass Surfaces

    public enum Glass {
        /// white 4% — inset rows, recessed areas
        public static let thinTint = AppColors.textPrimary.opacity(0.04)
        /// white 6% — standard glass tint for cards, chips, inputs
        public static let surface = AppColors.textPrimary.opacity(0.06)
        /// white 8% — mid glass, skeleton strokes, subtle separators
        public static let midTint = AppColors.textPrimary.opacity(0.08)
        /// white 10% — hover / active state
        public static let thickTint = AppColors.textPrimary.opacity(0.10)
        /// white 12% — card artwork border, specular highlights
        public static let highlight = AppColors.textPrimary.opacity(0.12)
        /// dark chrome for sidebar / toolbar
        public static let chrome = Color(red: 20 / 255, green: 22 / 255, blue: 30 / 255).opacity(0.65)
        /// recessed background for text inputs and selects
        public static let inputWell = AppColors.base.opacity(0.25)

        /// Specular gleam border gradient — shared by FDSCard, FDSLiquidButton, glass surfaces
        public static var gleamBorder: LinearGradient {
            LinearGradient(
                colors: [
                    AppColors.textPrimary.opacity(0.16),
                    AppColors.textPrimary.opacity(0.06),
                    .clear,
                    AppColors.base.opacity(0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Border Hierarchy

    public enum Border {
        /// white 6% — minimal container outline (decorative, does not meet WCAG 1.4.11 alone)
        public static let subtle = AppColors.textPrimary.opacity(0.06)
        /// white 10% — stronger container outline
        public static let strong = AppColors.textPrimary.opacity(0.10)
        /// white 25% — form field boundary (~3:1 on base, meets WCAG 1.4.11 Non-text Contrast)
        public static let input = AppColors.textPrimary.opacity(0.25)
        /// accent 70% — keyboard focus ring (visible, meets AA)
        public static let focus = AppColors.accentGreen.opacity(0.70)
    }

    // MARK: - Opacity Scale (for non-text decorative use only)

    public enum Opacity {
        public static let low: Double = 0.20
        public static let medium: Double = 0.30
        public static let muted: Double = 0.40
        public static let high: Double = 0.50
        public static let strong: Double = 0.80
    }

    // MARK: - Apple System Colors (HIG dark mode palette)

    public enum System {
        public static let red = Color(red: 1.0, green: 0.27, blue: 0.23) // #FF453A
        public static let orange = Color(red: 1.0, green: 0.62, blue: 0.04) // #FF9F0A
        public static let yellow = Color(red: 1.0, green: 0.84, blue: 0.04) // #FFD60A
        public static let green = Color(red: 0.19, green: 0.82, blue: 0.35) // #30D158
        public static let mint = Color(red: 0.40, green: 0.83, blue: 0.81) // #66D4CF
        public static let teal = Color(red: 0.25, green: 0.78, blue: 0.88) // #40C8E0
        public static let cyan = Color(red: 0.39, green: 0.82, blue: 1.0) // #64D2FF
        public static let blue = Color(red: 0.04, green: 0.52, blue: 1.0) // #0A84FF
        public static let indigo = Color(red: 0.37, green: 0.36, blue: 0.90) // #5E5CE6
        public static let purple = Color(red: 0.75, green: 0.35, blue: 0.95) // #BF5AF2
        public static let pink = Color(red: 1.0, green: 0.22, blue: 0.37) // #FF375F
        public static let gray = Color(red: 0.60, green: 0.60, blue: 0.62) // #98989D
    }
}
