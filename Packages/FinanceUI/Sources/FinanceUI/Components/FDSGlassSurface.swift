import FinanceCore
import SwiftUI

/// Liquid-glass surface using native SwiftUI materials.
///
/// Apple's pro app aesthetic: translucent, depth-aware, hairline border.
/// Use as primary container instead of flat dark rectangles.
public struct FDSGlassSurface<Content: View>: View {
    let content: Content
    let elevation: FDSElevation
    let cornerRadius: CGFloat
    let padding: CGFloat
    let strokeOpacity: Double

    public init(
        elevation: FDSElevation = .card,
        cornerRadius: CGFloat = AppRadius.lg,
        padding: CGFloat = AppSpacing.md,
        strokeOpacity: Double = 0.06,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.strokeOpacity = strokeOpacity
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background {
                if let material = elevation.material {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(material)
                        .background(AppColors.surface.opacity(0.25))
                } else {
                    Color.clear
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppColors.accentSlate.opacity(strokeOpacity * 1.5), lineWidth: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
