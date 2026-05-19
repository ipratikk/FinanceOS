import SwiftUI

// MARK: - Design Tokens — macOS Tahoe Liquid Glass

public enum DesignTokens {
    // MARK: - Wallpaper & Backgrounds (Liquid Glass)

    public enum Background {
        /// #0A0C11 — solid base before wallpaper tint
        public static let wallpaperBase = Color(red: 0.039, green: 0.047, blue: 0.067)
        /// white 6% — glass tint over wallpaper (cards, chips, inputs)
        public static let surfaceGlass = Color.white.opacity(0.06)
        /// white 10% — hover / active glass
        public static let surfaceGlassThick = Color.white.opacity(0.10)
        /// white 4% — inset rows, sheet hero
        public static let surfaceGlassThin = Color.white.opacity(0.04)
        /// chrome glass for sidebar/toolbar
        public static let chromeGlass = Color(red: 20/255, green: 22/255, blue: 30/255).opacity(0.65)
        /// black 25% — text input / select backgrounds (recessed)
        public static let inputWell = Color.black.opacity(0.25)
    }

    // MARK: - Apple System Colors (HIG dark mode)

    public enum System {
        public static let red = Color(red: 1.0, green: 0.27, blue: 0.23)      // #FF453A
        public static let orange = Color(red: 1.0, green: 0.62, blue: 0.04)   // #FF9F0A
        public static let yellow = Color(red: 1.0, green: 0.84, blue: 0.04)   // #FFD60A
        public static let green = Color(red: 0.19, green: 0.82, blue: 0.35)   // #30D158
        public static let mint = Color(red: 0.40, green: 0.83, blue: 0.81)    // #66D4CF
        public static let teal = Color(red: 0.25, green: 0.78, blue: 0.88)    // #40C8E0
        public static let cyan = Color(red: 0.39, green: 0.82, blue: 1.0)     // #64D2FF
        public static let blue = Color(red: 0.04, green: 0.52, blue: 1.0)     // #0A84FF
        public static let indigo = Color(red: 0.37, green: 0.36, blue: 0.90)  // #5E5CE6
        public static let purple = Color(red: 0.75, green: 0.35, blue: 0.95)  // #BF5AF2
        public static let pink = Color(red: 1.0, green: 0.22, blue: 0.37)     // #FF375F
        public static let gray = Color(red: 0.60, green: 0.60, blue: 0.62)    // #98989D
    }

    // MARK: - Semantic

    public enum Semantic {
        /// System.green — positive amounts, success states
        public static let credit = System.green
        /// System.red — negative amounts, debits
        public static let debit = System.red
        /// System.red — destructive actions
        public static let danger = System.red
        /// System.orange — caution states
        public static let warning = System.orange
        /// System.blue — informational
        public static let info = System.blue
        /// User-tweakable accent (default: System.orange)
        /// Can be overridden to System.blue (cobalt), System.purple (plum), System.green (emerald)
        public static let accent = System.orange
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
        public static let subtle = Color.white.opacity(0.06)
        /// white 10% — stronger borders
        public static let strong = Color.white.opacity(0.10)
        /// accent 50% — focus ring
        public static let focus = Semantic.accent.opacity(0.50)
    }

    public enum Edge {
        /// white 16% — specular highlight on top edge of glass surfaces
        public static let topGleam = Color.white.opacity(0.16)
        /// white 6% — mid highlight
        public static let topGleamMid = Color.white.opacity(0.06)
        /// black 20% — bottom shadow for depth
        public static let bottomShadow = Color.black.opacity(0.20)
    }

    // MARK: - Spacing (8pt grid)

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xl2: CGFloat = 32
        public static let xl3: CGFloat = 48
    }

    // MARK: - Corner Radius (concentric)

    public enum Radius {
        public static let xs: CGFloat = 6          // Chips, inputs
        public static let sm: CGFloat = 9          // Sidebar items, small buttons
        public static let md: CGFloat = 12         // Tiles, secondary cards
        public static let card: CGFloat = 18       // Standard cards
        public static let hero: CGFloat = 22       // Hero surfaces (dashboard net flow, ledger detail)
        public static let sheet: CGFloat = 20      // Modal sheets
        public static let capsule: CGFloat = .infinity  // Pills, chips, buttons, search inputs
    }

    // MARK: - Typography

    public enum Typography {
        // Display/Hero amounts
        public static let heroAmount = Font.system(size: 60, weight: .semibold, design: .default)
            .monospacedDigit()
        public static let ledgerAmount = Font.system(size: 38, weight: .semibold, design: .default)
            .monospacedDigit()
        public static let txnAmount = Font.system(size: 40, weight: .semibold, design: .default)
            .monospacedDigit()

        // Screen & Section titles
        public static let screenTitle = Font.system(size: 30, weight: .semibold, design: .default)
        public static let sectionTitle = Font.system(size: 17, weight: .semibold, design: .default)
        public static let sheetTitle = Font.system(size: 19, weight: .semibold, design: .default)

        // Metric cards
        public static let metricValue = Font.system(size: 28, weight: .semibold, design: .default)
            .monospacedDigit()

        // Body text
        public static let body = Font.system(size: 14, weight: .regular, design: .default)
        public static let txnRow = Font.system(size: 13.5, weight: .medium, design: .default)

        // Labels & captions
        public static let label = Font.system(size: 11, weight: .semibold, design: .default)
        public static let caption = Font.system(size: 11.5, weight: .regular, design: .default)
    }

    // MARK: - Materials

    public enum Material {
        /// .regularMaterial — cards, pills, chips, buttons
        public static let glass: SwiftUI.Material = .regularMaterial
        /// .thickMaterial — sheets, menus
        public static let glassThick: SwiftUI.Material = .thickMaterial
        /// .thinMaterial — lightweight surfaces
        public static let glassThin: SwiftUI.Material = .thinMaterial
        /// chrome for sidebar/toolbar (regularMaterial with overlay)
        public static let chrome: SwiftUI.Material = .regularMaterial
    }

    // MARK: - Motion

    public enum Motion {
        /// 120ms easeOut — hover transitions
        public static let fast = SwiftUI.Animation.easeOut(duration: 0.12)
        /// 180ms easeInOut — sheet appearance, default
        public static let standard = SwiftUI.Animation.easeInOut(duration: 0.18)
        /// spring — chip activations, toggles
        public static let spring = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.85)
        /// cubic bezier — sheet pop-in
        public static let sheetIn = SwiftUI.Animation.timingCurve(0.18, 0.70, 0.30, 1.0, duration: 0.22)
    }
}
