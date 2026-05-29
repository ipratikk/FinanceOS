import SwiftUI

/// FinanceOS material tokens. Use native SwiftUI materials, not custom blur.
///
/// Hierarchy:
/// - `base` — bottom of stack, app background
/// - `surface` — primary panels (sidebar, lists, sheets)
/// - `elevated` — floating elements (cards, popovers, tooltips)
/// - `prominent` — modal/overlay surfaces
public enum FDSMaterial {
    /// `.bar` — optimised for tab bars and sidebars.
    public static let bar: Material = .bar

    /// `.ultraThinMaterial` — subtle frosted surface for chips and inline cards.
    public static let ultraThin: Material = .ultraThinMaterial

    /// `.thinMaterial` — standard cards and list rows.
    public static let thin: Material = .thinMaterial

    /// `.regularMaterial` — sidebar and primary panel surfaces.
    public static let regular: Material = .regularMaterial

    /// `.thickMaterial` — floating popovers and sheet backgrounds.
    public static let thick: Material = .thickMaterial

    /// `.ultraThickMaterial` — modal sheet backgrounds at maximum depth.
    public static let prominent: Material = .ultraThickMaterial
}

/// Strict elevation hierarchy. One layer per section. Maps directly to `FDSMaterial` tokens.
public enum FDSElevation {
    /// No material — sits directly on the parent background.
    case flat

    /// `ultraThin` material — inline chip or tag.
    case chip

    /// `thin` material — card resting above the section background.
    case card

    /// `regular` material — floating element that overlays scrollable content.
    case floating

    /// `thick` material — modal sheets and popovers at maximum depth.
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
