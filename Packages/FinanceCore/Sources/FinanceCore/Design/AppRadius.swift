import Foundation

/// Design-token namespace for corner radii used throughout FinanceOS.
/// Use the most specific named token that matches the component type rather than raw CGFloat literals.
public enum AppRadius {
    /// 4pt — tight corners for compact elements (small badges, table cells).
    public static let xs: CGFloat = 4
    /// 8pt — subtle rounding for mid-size components (buttons, inputs).
    public static let sm: CGFloat = 8
    /// 12pt — standard panel and modal corner radius.
    public static let md: CGFloat = 12
    /// 16pt — card corner radius (account cards, transaction panels).
    public static let lg: CGFloat = 16
    /// 20pt — large panel and bottom-sheet corner radius.
    public static let xl: CGFloat = 20
    /// 28pt — full sheet / drawer corner radius.
    public static let xxl: CGFloat = 28
    /// 9999pt — pill / capsule shapes (tags, segmented controls).
    public static let full: CGFloat = 9999
    /// 6pt — inline chip and tag corner radius.
    public static let chip: CGFloat = 6
}
