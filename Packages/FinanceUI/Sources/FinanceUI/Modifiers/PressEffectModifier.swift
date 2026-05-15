import SwiftUI

public struct PressEffectModifier: ViewModifier {
    @State private var isPressed = false

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(AppAnimation.easeFast, value: isPressed)
            .onLongPressGesture(minimumDuration: 0.05, perform: {}, onPressingChanged: { isPressed in
                self.isPressed = isPressed
            })
    }
}

extension View {
    public func pressEffect() -> some View {
        modifier(PressEffectModifier())
    }
}
