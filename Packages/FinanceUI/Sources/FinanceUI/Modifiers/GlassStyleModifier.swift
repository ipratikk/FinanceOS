import SwiftUI

public struct GlassStyleModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(
                ZStack {
                    AppColors.surface2.opacity(0.5)
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColors.borderAccent.opacity(0.3), lineWidth: 1)
                }
            )
            .cornerRadius(AppRadius.md)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
    }
}

extension View {
    public func glassStyle() -> some View {
        modifier(GlassStyleModifier())
    }
}
