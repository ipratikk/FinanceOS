import FinanceCore
import SwiftUI

// MARK: - Flat Surface Modifier

struct GlassSurface: ViewModifier {
    let radius: CGFloat
    let tint: Color
    let strong: Bool

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(AppColors.surface2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppColors.border, lineWidth: 0.5)
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply flat surface styling.
    ///
    /// - Parameters:
    ///   - radius: Corner radius (default 18pt for standard cards)
    ///   - tint: Tint color (ignored, for backward compatibility)
    ///   - strong: Ignored, for backward compatibility
    ///   - lifted: Ignored, for backward compatibility
    func glassSurface(
        radius: CGFloat = 18,
        tint: Color = .white,
        strong: Bool = false,
        lifted: Bool = true
    ) -> some View {
        modifier(GlassSurface(radius: radius, tint: tint, strong: strong))
    }

    /// Flat pill variant using Capsule shape.
    ///
    /// - Parameters:
    ///   - strong: Ignored, for backward compatibility
    ///   - lifted: Ignored, for backward compatibility
    func glassPill(strong: Bool = false, lifted: Bool = false) -> some View {
        background {
            Capsule().fill(AppColors.surface2)
        }
        .overlay {
            Capsule().strokeBorder(AppColors.border, lineWidth: 0.5)
        }
    }
}
