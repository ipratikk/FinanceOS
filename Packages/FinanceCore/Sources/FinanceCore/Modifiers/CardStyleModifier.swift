import SwiftUI

public struct CardStyleModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColors.borderSubtle, lineWidth: 0.5)
            )
            .cornerRadius(AppRadius.md)
            .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius / 2, y: AppShadow.card.y / 2)
    }
}

public extension View {
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }
}
