import SwiftUI

public enum AppAnimation {
    // MARK: - Spring curves

    /// Fast selection spring — sidebar items, menus, toggles
    public static let selection: SwiftUI.Animation = .spring(response: 0.25, dampingFraction: 0.82)
    /// Standard spring — cards, panels
    public static let springSnappy: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.8)
    /// Bouncy spring — expressive reveals
    public static let springBouncy: SwiftUI.Animation = .spring(response: 0.45, dampingFraction: 0.72)

    // MARK: - Ease curves

    public static let easeSmooth: SwiftUI.Animation = .easeInOut(duration: 0.22)
    public static let easeFast: SwiftUI.Animation = .easeOut(duration: 0.14)
    public static let hover: SwiftUI.Animation = .easeOut(duration: 0.12)

    // MARK: - Reduce Motion

    /// Returns `full` animation when motion is allowed, `reduced` otherwise.
    /// Pass `reduceMotion` from `@Environment(\.accessibilityReduceMotion)`.
    ///
    /// Usage:
    /// ```swift
    /// @Environment(\.accessibilityReduceMotion) var reduceMotion
    /// .animation(AppAnimation.ifAllowed(springSnappy, reduceMotion: reduceMotion), value: isSelected)
    /// ```
    public static func ifAllowed(
        _ full: SwiftUI.Animation,
        reduceMotion: Bool,
        reduced: SwiftUI.Animation = .easeOut(duration: 0.1)
    ) -> SwiftUI.Animation {
        reduceMotion ? reduced : full
    }

    /// Instant (no animation) for use when reduce motion is on and even a reduced animation is undesirable.
    public static let instant: SwiftUI.Animation = .linear(duration: 0)
}

// MARK: - Reduce Motion View Modifier

/// Applies `animation` normally, or falls back to `.easeOut(duration: 0.1)` when Reduce Motion is enabled.
public struct MotionAwareAnimation<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let animation: SwiftUI.Animation
    let value: Value

    public func body(content: Content) -> some View {
        content.animation(
            AppAnimation.ifAllowed(animation, reduceMotion: reduceMotion),
            value: value
        )
    }
}

public extension View {
    /// Applies `animation` with automatic Reduce Motion fallback.
    func motionAnimation(_ animation: SwiftUI.Animation, value: some Equatable) -> some View {
        modifier(MotionAwareAnimation(animation: animation, value: value))
    }
}
