import FinanceCore
import SwiftUI

public struct GlassStyleModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(AppColors.surface.opacity(0.4))
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColors.accentCyan.opacity(0.15),
                                AppColors.accentBlue.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .cornerRadius(AppRadius.md)
            .shadow(
                color: AppColors.accentCyan.opacity(0.08),
                radius: 12,
                x: 0,
                y: 4
            )
    }
}

public extension View {
    func glassStyle() -> some View {
        modifier(GlassStyleModifier())
    }
}
