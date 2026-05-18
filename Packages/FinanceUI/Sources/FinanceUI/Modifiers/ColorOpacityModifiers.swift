import SwiftUI

extension Color {
    /// Surface divider: 0.06 opacity for subtle borders
    func divider() -> Color {
        self.opacity(0.06)
    }

    /// Border subtle: 0.08 opacity
    func borderSubtle() -> Color {
        self.opacity(0.08)
    }

    /// Border default: 0.12 opacity
    func borderDefault() -> Color {
        self.opacity(0.12)
    }

    /// Background overlay light: 0.03 opacity
    func overlayLight() -> Color {
        self.opacity(0.03)
    }

    /// Background overlay medium: 0.05 opacity
    func overlayMedium() -> Color {
        self.opacity(0.05)
    }

    /// Icon/button circle background: 0.1 opacity
    func buttonBackground() -> Color {
        self.opacity(0.1)
    }

    /// Skeleton loading state light: 0.04 opacity
    func skeletonLight() -> Color {
        self.opacity(0.04)
    }

    /// Skeleton loading state medium: 0.08 opacity
    func skeletonMedium() -> Color {
        self.opacity(0.08)
    }
}
