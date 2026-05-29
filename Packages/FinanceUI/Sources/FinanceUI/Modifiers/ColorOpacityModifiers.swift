import SwiftUI

/// Semantic opacity helpers on `Color`. Use these instead of inline `.opacity()` calls
/// so that token intent is preserved in code and easy to remap centrally.
extension Color {
    /// Surface divider: 0.06 opacity for subtle borders
    func divider() -> Color {
        opacity(0.06)
    }

    /// Border subtle: 0.08 opacity
    func borderSubtle() -> Color {
        opacity(0.08)
    }

    /// Border default: 0.12 opacity
    func borderDefault() -> Color {
        opacity(0.12)
    }

    /// Background overlay light: 0.03 opacity
    func overlayLight() -> Color {
        opacity(0.03)
    }

    /// Background overlay medium: 0.05 opacity
    func overlayMedium() -> Color {
        opacity(0.05)
    }

    /// Icon/button circle background: 0.1 opacity
    func buttonBackground() -> Color {
        opacity(0.1)
    }

    /// Skeleton loading state light: 0.04 opacity
    func skeletonLight() -> Color {
        opacity(0.04)
    }

    /// Skeleton loading state medium: 0.08 opacity
    func skeletonMedium() -> Color {
        opacity(0.08)
    }
}
