import SwiftUI

public struct GlassStyleModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColors.borderGlass, lineWidth: 0.5)
            )
            .cornerRadius(AppRadius.md)
    }
}

public extension View {
    func glassStyle() -> some View {
        modifier(GlassStyleModifier())
    }
}
