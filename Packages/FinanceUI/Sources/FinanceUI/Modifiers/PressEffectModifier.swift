import FinanceCore
import SwiftUI

public struct PressEffectModifier: ViewModifier {
    @State private var isPressed = false

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isPressed ? 0.85 : 1.0)
            .shadow(
                color: AppColors.accentGold.opacity(isPressed ? 0.1 : 0),
                radius: isPressed ? 6 : 0,
                x: 0,
                y: 0
            )
            .animation(AppAnimation.easeFast, value: isPressed)
            .onLongPressGesture(minimumDuration: 0.05, perform: {}, onPressingChanged: { isPressed in
                self.isPressed = isPressed
            })
    }
}

public extension View {
    func pressEffect() -> some View {
        modifier(PressEffectModifier())
    }
}
