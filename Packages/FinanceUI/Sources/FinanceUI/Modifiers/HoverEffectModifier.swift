import FinanceCore
import SwiftUI

/// macOS-only hover effect: 1% scale-up, glass background tint, and accent glow shadow.
///
/// No-ops on iOS/watchOS. Use `.hoverEffect()` convenience extension.
/// Avoid stacking with `PressEffectModifier` — they conflict on scale.
public struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false

    public func body(content: Content) -> some View {
        #if os(macOS)
        content
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .background(AppColors.glass.opacity(isHovered ? 0.5 : 0))
            .shadow(
                color: AppColors.accent.opacity(isHovered ? 0.12 : 0),
                radius: isHovered ? 12 : 0,
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
    /// Applies macOS hover: scale, glass tint, and accent glow. No-op on iOS.
    func hoverEffect() -> some View {
        modifier(HoverEffectModifier())
    }
}
