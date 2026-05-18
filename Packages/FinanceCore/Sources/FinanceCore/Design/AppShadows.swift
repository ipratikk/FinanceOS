import SwiftUI

/// Semantic shadow system for FinanceOS.
/// All shadows must use these constants for consistent elevation hierarchy.
public enum AppShadows {
    // MARK: - Elevation Levels

    public static let subtle = Shadow(
        color: Color.black.opacity(0.05),
        radius: 4,
        x: 0,
        y: 2
    )

    public static let standard = Shadow(
        color: Color.black.opacity(0.08),
        radius: 8,
        x: 0,
        y: 4
    )

    public static let elevated = Shadow(
        color: Color.black.opacity(0.12),
        radius: 16,
        x: 0,
        y: 8
    )

    public static let prominent = Shadow(
        color: Color.black.opacity(0.16),
        radius: 24,
        x: 0,
        y: 12
    )

    // MARK: - Shadow Struct

    public struct Shadow: Sendable {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat

        public func apply(to view: some View) -> some View {
            view.shadow(color: color, radius: radius, x: x, y: y)
        }
    }
}
