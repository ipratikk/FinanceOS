import SwiftUI

public enum AppAnimation {
    /// Liquid selection — fast spring for sidebar/menu items
    public static let selection: SwiftUI.Animation = .spring(response: 0.25, dampingFraction: 0.82)

    // Spring curves
    public static let springSnappy: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.8)
    public static let springBouncy: SwiftUI.Animation = .spring(response: 0.45, dampingFraction: 0.72)

    // Ease curves
    public static let easeSmooth: SwiftUI.Animation = .easeInOut(duration: 0.22)
    public static let easeFast: SwiftUI.Animation = .easeOut(duration: 0.14)
    public static let hover: SwiftUI.Animation = .easeOut(duration: 0.12)
}
