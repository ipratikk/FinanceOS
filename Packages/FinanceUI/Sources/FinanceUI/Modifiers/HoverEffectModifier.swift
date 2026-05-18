import FinanceCore
import SwiftUI

public struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false

    public func body(content: Content) -> some View {
        #if os(macOS)
        content
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .background(AppColors.glass.opacity(isHovered ? 0.5 : 0))
            .shadow(
                color: AppColors.accentGold.opacity(isHovered ? 0.08 : 0),
                radius: isHovered ? 8 : 0,
                x: 0,
                y: 0
            )
            .animation(AppAnimation.hover, value: isHovered)
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
