import FinanceCore
import SwiftUI

// MARK: - Glass Modifier Usage Guide

//
// Two glass modifiers exist. Do NOT use both on the same view.
//
// `.glassStyle()` — legacy, uses .ultraThinMaterial + AppColors.surface tint.
//   Use for: older list rows, legacy card wrappers being phased out.
//   Blur level: thin (ultraThinMaterial).
//
// `.glassSurface(radius:tint:strong:liftShadow:)` — preferred for all new surfaces.
//   Use for: FDSCard, modals, panels, chips, sidebars, toolbars.
//   Blur level: regular (.regularMaterial). Supports elevation shadow via liftShadow.
//
// Migration: replace .glassStyle() with .glassSurface() when touching legacy views in Phase 3.

public struct GlassStyleModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(.ultraThinMaterial)
            .background(AppColors.surface.opacity(0.4))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColors.accentSlate.opacity(0.08), lineWidth: 0.5)
            )
            .cornerRadius(AppRadius.md)
            .shadow(color: AppColors.base.opacity(0.15), radius: 8, x: 0, y: 2)
    }
}

public extension View {
    func glassStyle() -> some View {
        modifier(GlassStyleModifier())
    }
}
