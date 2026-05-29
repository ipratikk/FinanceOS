import FinanceCore
import SwiftUI

// MARK: - Glass Surface Modifier

//
// Uses the native macOS 26 .glassEffect() API (Liquid Glass).
// The system handles blur, tint, specular highlights, light/dark adaptation,
// and Reduce Transparency fallback automatically.

/// ViewModifier that applies the native macOS 26 `glassEffect` with optional elevation shadow.
///
/// Do not apply both `GlassSurface` and `GlassStyleModifier` to the same view.
/// Prefer the `.glassSurface()` convenience extension over constructing this directly.
public struct GlassSurface: ViewModifier {
    /// Corner radius passed to `RoundedRectangle` inside `glassEffect`.
    let radius: CGFloat
    /// When true, adds a 12pt black-opacity drop shadow to suggest elevation.
    let liftShadow: Bool

    public func body(content: Content) -> some View {
        content
            .glassEffect(in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(
                color: .black.opacity(liftShadow ? 0.20 : 0),
                radius: liftShadow ? 12 : 0,
                y: liftShadow ? 4 : 0
            )
    }
}

// MARK: - View Extensions

public extension View {
    /// Apply Liquid Glass surface (macOS 26 native .glassEffect).
    ///
    /// - Parameters:
    ///   - radius: Corner radius. Defaults to `AppRadius.lg` (16pt).
    ///   - lifted: Add drop shadow to suggest elevation. Default true.
    func glassSurface(
        radius: CGFloat = AppRadius.lg,
        lifted: Bool = true
    ) -> some View {
        modifier(GlassSurface(radius: radius, liftShadow: lifted))
    }

    /// Glass pill — Liquid Glass with a Capsule clip shape.
    func glassPill() -> some View {
        glassEffect(in: Capsule())
    }
}
