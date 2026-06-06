import SwiftUI

/// Semantic shadow system for FinanceOS.
/// All shadows must use these constants for consistent elevation hierarchy.
public enum AppShadows {
    // MARK: - Elevation Levels

    /// r4 y2 — barely lifted surface; use on list rows, chips, and input fields.
    public static let subtle = Shadow(
        color: Color.black.opacity(0.40),
        radius: 4,
        offsetX: 0,
        offsetY: 2
    )

    /// r8 y4 — standard card elevation; use on dashboard cards and panels.
    public static let standard = Shadow(
        color: Color.black.opacity(0.50),
        radius: 8,
        offsetX: 0,
        offsetY: 4
    )

    /// r16 y8 — elevated overlay; use on popovers, tooltips, and floating action elements.
    public static let elevated = Shadow(
        color: Color.black.opacity(0.60),
        radius: 16,
        offsetX: 0,
        offsetY: 8
    )

    /// r24 y12 — highest elevation; use on modal sheets and drop-target highlights.
    public static let prominent = Shadow(
        color: Color.black.opacity(0.70),
        radius: 24,
        offsetX: 0,
        offsetY: 12
    )

    // MARK: - Shadow Struct

    /// A fully-resolved shadow descriptor; apply via `shadow.apply(to:)` or destructure into `.shadow()` modifiers.
    public struct Shadow: Sendable {
        public let color: Color
        public let radius: CGFloat
        public let offsetX: CGFloat
        public let offsetY: CGFloat

        /// Applies this shadow to `view` using the stored parameters.
        public func apply(to view: some View) -> some View {
            view.shadow(color: color, radius: radius, x: offsetX, y: offsetY)
        }
    }
}
