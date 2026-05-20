import Foundation

public enum AppSpacing {
    // Legacy values (kept for backward compatibility in existing views)
    public static let xxxs: CGFloat = 2
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12 // Keep until Phase 2 view rewrites
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 20 // Keep until Phase 2 view rewrites
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 40
    public static let section: CGFloat = 48

    // New 8pt-aligned aliases for Phase 2+ views
    public static let tight: CGFloat = 4 // Tighter gaps, replaces xxxs
    public static let compact: CGFloat = 8 // Use instead of xs for clarity

    // Component-specific targets
    public static let hitTarget: CGFloat = 44
    public static let minTouchTarget: CGFloat = 44

    // MARK: - Density Modes

    public struct DensityMap {
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

        public var spacing: DensityMap {
            switch self {
            case .standard:
                return DensityMap(xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32)
            case .compact:
                return DensityMap(xs: 2, sm: 4, md: 8, lg: 12, xl: 16, xxl: 24)
            }
        }
    }

    // MARK: - Layout Constants

    public enum Layout {
        /// Standard sidebar width. Replaces any hardcoded 232.
        public static let sidebarWidth: CGFloat = 232
    }
}
