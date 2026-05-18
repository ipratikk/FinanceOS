import SwiftUI

/// Semantic spacing system for FinanceOS.
/// All padding/frame spacing must use these constants.
/// Do NOT use hardcoded numeric padding values.
public enum AppSpacing {
    // MARK: - Hairline & Tight Spacing

    public static let xxs: CGFloat = 2.0
    public static let xs: CGFloat = 4.0

    // MARK: - Compact & Default Spacing

    public static let sm: CGFloat = 8.0
    public static let md: CGFloat = 16.0

    // MARK: - Comfortable & Large Spacing

    public static let lg: CGFloat = 24.0
    public static let xl: CGFloat = 32.0

    // MARK: - Component Hit Targets

    public static let hitTarget: CGFloat = 44.0
    public static let minTouchTarget: CGFloat = 44.0

    // MARK: - Dialog/Modal Sizes

    public static let sheetSmall = CGSize(width: 480, height: 560)
    public static let sheetMedium = CGSize(width: 540, height: 720)
    public static let sheetLarge = CGSize(width: 600, height: 800)

    // MARK: - Sidebar & Layout Widths

    public static let sidebarWidth: CGFloat = 220.0
    public static let maxContentWidth: CGFloat = 800.0

    // MARK: - Rounded Corners

    public static let cornerRadiusXS: CGFloat = 4.0
    public static let cornerRadiusSm: CGFloat = 8.0
    public static let cornerRadiusMd: CGFloat = 12.0
    public static let cornerRadiusLg: CGFloat = 16.0
}
