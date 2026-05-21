import FinanceCore
import SwiftUI

/// Liquid Glass surface — native macOS 26 glass effect with elevation semantics.
///
/// Use `FDSCard` for most cases. `FDSGlassSurface` is for when you need
/// explicit elevation control (chip, floating, modal).
public struct FDSGlassSurface<Content: View>: View {
    let content: Content
    let elevation: FDSElevation
    let cornerRadius: CGFloat
    let padding: CGFloat

    public init(
        elevation: FDSElevation = .card,
        cornerRadius: CGFloat = AppRadius.lg,
        padding: CGFloat = AppSpacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
