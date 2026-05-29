import Foundation

/// Design-token namespace for all spacing values used in FinanceOS layouts and components.
/// All values follow an 8pt grid; prefer canonical tokens over raw literals in new code.
public enum AppSpacing {
    // MARK: - Canonical 8pt-aligned scale

    /// 4pt — micro gap between tightly coupled elements (icon + label, badge + text).
    public static let tight: CGFloat = 4
    /// 8pt — compact intra-component gap (list row internal padding, chip padding).
    public static let compact: CGFloat = 8
    /// 12pt — small inter-element gap (stack spacing inside a card).
    public static let sm: CGFloat = 12
    /// 16pt — standard component padding and inter-section gap.
    public static let md: CGFloat = 16
    /// 24pt — large inter-section gap and card padding.
    public static let xl: CGFloat = 24
    /// 32pt — extra-large section gap (between dashboard cards).
    public static let xxl: CGFloat = 32
    /// 40pt — hero section vertical breathing room.
    public static let xxxl: CGFloat = 40
    /// 48pt — top-level section separator / screen edge padding on large layouts.
    public static let section: CGFloat = 48
    public static let x4l: CGFloat = 48
    public static let x5l: CGFloat = 56
    public static let x6l: CGFloat = 64

    // MARK: - Legacy values (kept for source compatibility — prefer canonical scale in new code)

    public static let xxxs: CGFloat = 2 // legacy — use tight (4)
    public static let xxs: CGFloat = 4 // legacy — use tight (4)
    public static let xs: CGFloat = 8 // legacy — use compact (8)
    public static let lg: CGFloat = 20 // legacy — not 8pt-aligned; use md (16) or xl (24)

    // MARK: - Component-specific targets

    /// Minimum Apple HIG tap target size — apply to any interactive element smaller than 44pt.
    public static let hitTarget: CGFloat = 44
    public static let minTouchTarget: CGFloat = 44

    // MARK: - Density Modes

    /// A resolved set of spacing values for a given display density.
    public struct DensityMap {
        public let xs: CGFloat
        public let sm: CGFloat
        public let md: CGFloat
        public let lg: CGFloat
        public let xl: CGFloat
        public let xxl: CGFloat
    }

    /// Two-level density mode: `standard` for normal use, `compact` for information-dense list views.
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
