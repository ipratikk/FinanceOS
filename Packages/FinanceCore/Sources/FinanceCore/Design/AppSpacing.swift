import Foundation

public enum AppSpacing {
    // MARK: - Canonical 8pt-aligned scale

    public static let tight: CGFloat = 4
    public static let compact: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 40
    public static let section: CGFloat = 48

    // MARK: - Legacy values (kept for source compatibility — prefer canonical scale in new code)

    public static let xxxs: CGFloat = 2 // legacy — use tight (4)
    public static let xxs: CGFloat = 4 // legacy — use tight (4)
    public static let xs: CGFloat = 8 // legacy — use compact (8)
    public static let lg: CGFloat = 20 // legacy — not 8pt-aligned; use md (16) or xl (24)

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
