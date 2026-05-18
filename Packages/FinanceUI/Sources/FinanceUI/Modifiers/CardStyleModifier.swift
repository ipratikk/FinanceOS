import FinanceCore
import SwiftUI

public struct CardStyleModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(.ultraThinMaterial)
            .background(AppColors.surface.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColors.accentCyan.opacity(0.2),
                                AppColors.accentCyan.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .cornerRadius(AppRadius.md)
            .shadow(
                color: AppColors.accentCyan.opacity(0.1),
                radius: 20,
                x: 0,
                y: 10
            )
    }
}

public extension View {
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }
}
