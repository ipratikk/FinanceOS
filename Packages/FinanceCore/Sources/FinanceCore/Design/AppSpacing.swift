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
}
