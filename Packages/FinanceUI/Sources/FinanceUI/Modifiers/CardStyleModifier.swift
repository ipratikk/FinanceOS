import FinanceCore
import SwiftUI

/// Applies standard card chrome: `ultraThinMaterial` blur, `surface` tint, accent border,
/// rounded corners, and an elevation shadow. Use `.cardStyle()` convenience method.
///
/// For Liquid Glass cards, use `FDSCard` or `.glassSurface()` instead.
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
            .shadow(color: AppColors.base.opacity(0.3), radius: 16, x: 0, y: 8)
    }
}

public extension View {
    /// Applies standard FDS card chrome (material + border + shadow).
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }
}
