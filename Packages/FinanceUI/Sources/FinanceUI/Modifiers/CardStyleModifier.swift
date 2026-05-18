import FinanceCore
import SwiftUI

public struct CardStyleModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(.ultraThinMaterial)
            .background(AppColors.surface.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColors.accentGold.opacity(0.12), lineWidth: 0.5)
            )
            .cornerRadius(AppRadius.md)
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 12,
                x: 0,
                y: 4
            )
    }
}

public extension View {
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }
}
