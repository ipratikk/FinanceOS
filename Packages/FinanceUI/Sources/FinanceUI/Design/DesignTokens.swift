import FinanceCore
import SwiftUI

// MARK: - Design Tokens

/// Neon-accent color tokens from DESIGN_SYSTEM.md.
/// Backgrounds and neutrals live in AppColors (FinanceCore).
public enum DesignTokens {
    // MARK: - Neon Backgrounds (cyberpunk palette)

    public enum Background {
        /// #0D0D14 — page background
        public static let midnight = Color(red: 0.051, green: 0.051, blue: 0.078)
        /// #141420 — card/container background
        public static let surface = Color(red: 0.078, green: 0.078, blue: 0.125)
        /// #1A1A28 — hover / elevated state
        public static let elevated = Color(red: 0.102, green: 0.102, blue: 0.157)
        /// #0D0D14 at 0.7 — modal backdrop
        public static let overlay = Color(red: 0.051, green: 0.051, blue: 0.078).opacity(0.7)
    }

    // MARK: - Neon Accents

    public enum Accent {
        /// #00F0FF — primary action, data highlight
        public static let cyan = Color(red: 0, green: 0.941, blue: 1.0)
        /// #3399FF — secondary, charts
        public static let blue = Color(red: 0.2, green: 0.6, blue: 1.0)
        /// #CC33FF — tertiary, badges
        public static let purple = Color(red: 0.8, green: 0.2, blue: 1.0)
        /// #FF1B9D — alerts, warnings
        public static let pink = Color(red: 1.0, green: 0.106, blue: 0.616)
        /// #66FF00 — positive, gains
        public static let lime = Color(red: 0.4, green: 1.0, blue: 0)
        /// #FF6600 — negative, losses
        public static let orange = Color(red: 1.0, green: 0.4, blue: 0)
    }

    // MARK: - Semantic

    public enum Semantic {
        /// #00D966 — positive states
        public static let success = Color(red: 0, green: 0.851, blue: 0.4)
        /// #FF3333 — destructive actions
        public static let danger = Color(red: 1.0, green: 0.2, blue: 0.2)
        /// #FFB800 — caution states
        public static let warning = Color(red: 1.0, green: 0.722, blue: 0)
        /// #00B4FF — informational
        public static let info = Color(red: 0, green: 0.706, blue: 1.0)
    }

    // MARK: - Text

    public enum Text {
        /// #FFFFFF
        public static let primary = Color.white
        /// #B3B3C4
        public static let secondary = Color(red: 0.702, green: 0.702, blue: 0.769)
        /// #808090
        public static let tertiary = Color(red: 0.502, green: 0.502, blue: 0.565)
    }

    // MARK: - Borders

    public enum Border {
        /// rgba(42, 42, 62, 0.3)
        public static let subtle = Color(red: 0.165, green: 0.165, blue: 0.243).opacity(0.3)
        /// rgba(0, 240, 255, 0.2) — accent cyan border
        public static let strong = Accent.cyan.opacity(0.2)
        /// rgba(0, 240, 255, 0.4) — focused
        public static let focus = Accent.cyan.opacity(0.4)
    }

    // MARK: - Spacing (8pt grid, per DESIGN_SYSTEM.md)

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xl2: CGFloat = 32
        public static let xl3: CGFloat = 48
    }

    // MARK: - Typography

    public enum Typography {
        // Display
        public static let displayXL = Font.system(size: 48, weight: .bold, design: .default)
        public static let displayL = Font.system(size: 40, weight: .bold, design: .default)
        // Headline
        public static let headlineL = Font.system(size: 32, weight: .semibold, design: .default)
        public static let headlineM = Font.system(size: 24, weight: .semibold, design: .default)
        // Title
        public static let titleL = Font.system(size: 20, weight: .semibold, design: .default)
        public static let titleM = Font.system(size: 18, weight: .semibold, design: .default)
        // Body
        public static let bodyL = Font.system(size: 16, weight: .regular, design: .default)
        public static let bodyM = Font.system(size: 14, weight: .regular, design: .default)
        public static let bodyS = Font.system(size: 13, weight: .regular, design: .default)
        // Label
        public static let labelM = Font.system(size: 12, weight: .medium, design: .default)
        public static let labelS = Font.system(size: 11, weight: .medium, design: .default)
        /// Caption
        public static let caption = Font.system(size: 10, weight: .regular, design: .default)
        /// Mono (amounts)
        public static let monoAmount = Font.system(size: 20, weight: .semibold, design: .monospaced)
        // Icons
        public static let iconMd = Font.system(size: 16, weight: .regular)
        public static let iconSm = Font.system(size: 14, weight: .regular)
    }

    // MARK: - Corner Radius

    public enum Radius {
        public static let sm: CGFloat = 4
        public static let md: CGFloat = 8
        public static let lg: CGFloat = 12
        public static let card: CGFloat = 16
        public static let button: CGFloat = 12
    }

    // MARK: - Animation

    public enum Anim {
        public static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        public static let hover = SwiftUI.Animation.easeOut(duration: 0.15)
        public static let microSpring = SwiftUI.Animation.spring(
            response: 0.2,
            dampingFraction: 0.8
        )
        public static let press = SwiftUI.Animation.easeInOut(duration: 0.08)
    }
}
