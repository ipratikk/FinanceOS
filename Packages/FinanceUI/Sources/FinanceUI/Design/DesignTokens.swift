import FinanceCore
import SwiftUI

// MARK: - Design Tokens — macOS Tahoe Liquid Glass

//
// Canonical token hierarchy:
//   App* (FinanceCore) — spacing, radius, animation, shadow, color
//   DesignTokens       — FinanceUI-specific semantic color, typography,
//                        glass surfaces, elevation, density, and layout.
//
// Views should use AppSpacing, AppRadius, AppAnimation, AppShadows directly.
// DesignTokens.Spacing / .Radius / .Animation / .Shadow are thin facade
// typealiases pointing to the App* canonical values.
//
// Do NOT add new spacing/radius/animation values here; extend App* in FinanceCore.

public enum DesignTokens {
    // MARK: - Re-exported App* Tokens (canonical from FinanceCore)

    /// Use AppSpacing directly. This typealias keeps DesignTokens-qualified call sites compiling.
    public typealias Spacing = AppSpacing
    /// Use AppRadius directly. This typealias keeps DesignTokens-qualified call sites compiling.
    public typealias Radius = AppRadius
    /// Use AppAnimation directly. This typealias keeps DesignTokens-qualified call sites compiling.
    public typealias Animation = AppAnimation
    /// Use AppShadows directly. This typealias keeps DesignTokens-qualified call sites compiling.
    public typealias Shadow = AppShadows

    // MARK: - Wallpaper & Backgrounds (Liquid Glass)

    public enum Background {
        /// #0A0C11 — solid base before wallpaper tint
        public static let wallpaperBase = Color(red: 0.039, green: 0.047, blue: 0.067)
        /// white 6% — glass tint over wallpaper (cards, chips, inputs)
        public static let surfaceGlass = AppColors.textPrimary.opacity(0.06)
        /// white 10% — hover / active glass
        public static let surfaceGlassThick = AppColors.textPrimary.opacity(0.10)
        /// white 4% — inset rows, sheet hero
        public static let surfaceGlassThin = AppColors.textPrimary.opacity(0.04)
        /// chrome glass for sidebar/toolbar
        public static let chromeGlass = Color(
            red: 20 / 255,
            green: 22 / 255,
            blue: 30 / 255
        ).opacity(0.65)
        /// white 8% — mid glass (skeleton strokes, subtle separators)
        public static let surfaceGlassMid = AppColors.textPrimary.opacity(0.08)
        /// white 12% — card artwork border, light stroke highlights
        public static let surfaceGlassHighlight = AppColors.textPrimary.opacity(0.12)
        /// black 25% — text input / select backgrounds (recessed)
        public static let inputWell = AppColors.base.opacity(0.25)
    }

    // MARK: - Apple System Colors (HIG dark mode)

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

    // MARK: - Semantic Colors

    //
    // `success` = credit/green, `error` = debit/danger/red.
    // Use these for status badges, state indicators, and feedback UI.
    // For transaction amounts use AppColors.credit / AppColors.debit directly.

    public enum Semantic {
        /// AppColors.credit — positive amounts, success states (System green)
        public static let credit = AppColors.credit
        /// AppColors.debit — negative amounts (System red)
        public static let debit = AppColors.debit
        /// AppColors.danger — destructive actions (System red)
        public static let danger = AppColors.danger
        /// AppColors.warning — caution states (#FF9500)
        public static let warning = AppColors.warning
        /// AppColors.info — informational (#0A84FF)
        public static let info = AppColors.info
        /// User-tweakable accent (default: AppColors.accentGreen)
        public static let accent = AppColors.accent
        /// AppColors.success — maps to System green. Use for success badges, confirmations.
        public static let success = AppColors.success
        /// AppColors.danger — maps to System red. Use for error badges, validation failures.
        public static let error = AppColors.danger
    }

    // MARK: - Text

    public enum Text {
        /// #F1F3F6
        public static let primary = Color(red: 0.945, green: 0.953, blue: 0.965)
        /// #BDC2CC
        public static let secondary = Color(red: 0.741, green: 0.761, blue: 0.800)
        /// #858A94
        public static let tertiary = Color(red: 0.518, green: 0.541, blue: 0.580)
        /// #555A64
        public static let quaternary = Color(red: 0.333, green: 0.353, blue: 0.392)
    }

    // MARK: - Borders & Edge Highlights

    public enum Border {
        /// white 6% — subtle borders
        public static let subtle = AppColors.textPrimary.opacity(0.06)
        /// white 10% — stronger borders
        public static let strong = AppColors.textPrimary.opacity(0.10)
        /// accent 50% — focus ring
        public static let focus = Semantic.accent.opacity(0.50)
    }

    public enum Edge {
        /// white 16% — specular highlight on top edge of glass surfaces
        public static let topGleam = AppColors.textPrimary.opacity(0.16)
        /// white 6% — mid highlight
        public static let topGleamMid = AppColors.textPrimary.opacity(0.06)
        /// black 20% — bottom shadow for depth
        public static let bottomShadow = AppColors.base.opacity(0.20)

        /// Shared gleam border gradient used by FDSCard, FDSLiquidButton, and glass surfaces.
        public static var gleamBorder: LinearGradient {
            LinearGradient(
                colors: [topGleam, topGleamMid, .clear, bottomShadow],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Elevation (Shadow Lift Tiers)

    //
    // Three-level elevation system mapping to AppShadows.
    // lift1 = subtle resting state, lift2 = hovered/active, lift3 = floating.

    public enum Elevation {
        /// Resting elevation — cards, rows (AppShadows.subtle)
        public static let lift1 = AppShadows.subtle
        /// Active / hovered elevation — cards on hover (AppShadows.standard)
        public static let lift2 = AppShadows.standard
        /// Floating elevation — popovers, menus (AppShadows.elevated)
        public static let lift3 = AppShadows.elevated
    }

    // MARK: - Density Modes

    //
    // Switch layouts between `standard` (default) and `compact` density.
    // Each mode provides a complete spacing map.
    // Usage: `DesignTokens.Density.compact.spacing.md`

    public struct DensitySpacingMap {
        public let xs: CGFloat
        public let sm: CGFloat
        public let md: CGFloat
        public let lg: CGFloat
        public let xl: CGFloat
        public let xxl: CGFloat
    }

    public enum Density {
        case standard
        case compact

        public var spacing: DensitySpacingMap {
            switch self {
            case .standard:
                return DensitySpacingMap(xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32)
            case .compact:
                return DensitySpacingMap(xs: 2, sm: 4, md: 8, lg: 12, xl: 16, xxl: 24)
            }
        }
    }

    // MARK: - Opacity Scale

    //
    // Use these for `.opacity()` modifiers on Dividers, icons, and decorative shapes.
    // Do NOT apply to text or interactive components — use semantic color tokens instead.

    public enum Opacity {
        /// 0.20 — subtle separators, dividers
        public static let low: Double = 0.20
        /// 0.30 — soft dividers, ghost icons
        public static let medium: Double = 0.30
        /// 0.40 — muted icon states
        public static let muted: Double = 0.40
        /// 0.50 — mid-weight overlays
        public static let high: Double = 0.50
        /// 0.80 — near-opaque tinted overlays
        public static let strong: Double = 0.80
    }

    // MARK: - Layout Constants

    public enum Layout {
        /// Standard sidebar width (232pt). Replaces any hardcoded literal 232.
        public static let sidebarWidth: CGFloat = 232
    }
}
