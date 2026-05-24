import SwiftUI

/// Semantic shadow system for FinanceOS.
/// All shadows must use these constants for consistent elevation hierarchy.
public enum AppShadows {
    // MARK: - Elevation Levels

    public static let subtle = Shadow(
        color: Color.black.opacity(0.40),
        radius: 4,
        offsetX: 0,
        offsetY: 2
    )

    public static let standard = Shadow(
        color: Color.black.opacity(0.50),
        radius: 8,
        offsetX: 0,
        offsetY: 4
    )

    public static let elevated = Shadow(
        color: Color.black.opacity(0.60),
        radius: 16,
        offsetX: 0,
        offsetY: 8
    )

    public static let prominent = Shadow(
        color: Color.black.opacity(0.70),
        radius: 24,
        offsetX: 0,
        offsetY: 12
    )

    // MARK: - Shadow Struct

    public struct Shadow: Sendable {
        public let color: Color
        public let radius: CGFloat
        public let offsetX: CGFloat
        public let offsetY: CGFloat

        public func apply(to view: some View) -> some View {
            view.shadow(color: color, radius: radius, x: offsetX, y: offsetY)
        }
    }
}
