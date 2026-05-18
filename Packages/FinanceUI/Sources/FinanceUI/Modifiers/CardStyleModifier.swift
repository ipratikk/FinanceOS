import FinanceCore
import SwiftUI

public struct CardStyleModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(AppSpacing.lg)
            .background(.ultraThinMaterial)
            .background(AppColors.surface.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.accent.opacity(0.15), lineWidth: 0.5)
            )
            .cornerRadius(AppRadius.lg)
            .shadow(
                color: Color.black.opacity(0.3),
                radius: 16,
                x: 0,
                y: 8
            )
    }
}

public extension View {
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }
}
