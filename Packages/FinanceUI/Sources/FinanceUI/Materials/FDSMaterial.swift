import SwiftUI

/// FinanceOS material tokens. Use native SwiftUI materials, not custom blur.
///
/// Hierarchy:
/// - `base` — bottom of stack, app background
/// - `surface` — primary panels (sidebar, lists, sheets)
/// - `elevated` — floating elements (cards, popovers, tooltips)
/// - `prominent` — modal/overlay surfaces
public enum FDSMaterial {
    /// Tab bar / sidebar background.
    public static let bar: Material = .bar

    /// Subtle frosted panels (chips, inline cards).
    public static let ultraThin: Material = .ultraThinMaterial

    /// Standard cards, list rows.
    public static let thin: Material = .thinMaterial

    /// Sidebar, primary surfaces.
    public static let regular: Material = .regularMaterial

    /// Floating popovers, sheets.
    public static let thick: Material = .thickMaterial

    /// Modal sheet backgrounds, highest depth.
    public static let prominent: Material = .ultraThickMaterial
}

/// Strict elevation hierarchy. One layer per section.
public enum FDSElevation {
    /// Flat — sits on parent surface.
    case flat

    /// Inline chip / tag elevation.
    case chip

    /// Card surface — rests above section.
    case card

    /// Floating element — overlays content.
    case floating

    /// Modal — sheets, popovers.
    case modal

    public var material: Material? {
        switch self {
        case .flat:
            nil
        case .chip:
            FDSMaterial.ultraThin
        case .card:
            FDSMaterial.thin
        case .floating:
            FDSMaterial.regular
        case .modal:
            FDSMaterial.thick
        }
    }
}
