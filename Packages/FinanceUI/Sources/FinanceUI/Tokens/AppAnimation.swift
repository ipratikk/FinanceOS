import SwiftUI

public enum AppAnimation {
    public static let springSnappy: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.8)
    public static let springBouncy: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.7)
    public static let easeSmooth: SwiftUI.Animation = .easeInOut(duration: 0.25)
    public static let easeFast: SwiftUI.Animation = .easeOut(duration: 0.15)
}
