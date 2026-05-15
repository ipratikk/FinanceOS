import SwiftUI

public struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false

    public func body(content: Content) -> some View {
        #if os(macOS)
        content
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .background(AppColors.surface2.opacity(isHovered ? 0.5 : 0))
            .animation(AppAnimation.easeFast, value: isHovered)
            .onContinuousHover { phase in
                switch phase {
                case .active:
                    isHovered = true
                case .ended:
                    isHovered = false
                }
            }
        #else
        content
        #endif
    }
}

public extension View {
    func hoverEffect() -> some View {
        modifier(HoverEffectModifier())
    }
}
