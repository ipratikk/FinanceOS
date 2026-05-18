import SwiftUI

/// Standard animation durations and curves for FinanceOS.
/// All animations must use these constants for consistency.
public enum AppAnimation {
    // MARK: - Standard Durations

    public static let fast: TimeInterval = 0.15
    public static let normal: TimeInterval = 0.25
    public static let slow: TimeInterval = 0.35

    // MARK: - Spring Animations

    public static let springSnappy: Animation = .spring(response: 0.3, dampingFraction: 0.75)
    public static let springBouncy: Animation = .spring(response: 0.45, dampingFraction: 0.6)

    // MARK: - Easing Curves

    public static let easeInOut = Animation.easeInOut(duration: Self.normal)
    public static let easeIn = Animation.easeIn(duration: Self.normal)
    public static let easeOut = Animation.easeOut(duration: Self.normal)

    // MARK: - Preset Animations

    public static let selection = Animation.spring(response: 0.2, dampingFraction: 0.8)
    public static let transition = Animation.easeInOut(duration: Self.normal)
    public static let dismiss = Animation.easeOut(duration: Self.fast)
}
