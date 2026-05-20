import FinanceCore
import SwiftUI

// MARK: - Glass Surface Modifier

struct GlassSurface: ViewModifier {
    let radius: CGFloat
    let tint: Color
    let strong: Bool
    let liftShadow: Bool

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(.regularMaterial)
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(tint.opacity(strong ? 0.10 : 0.06))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                AppColors.textPrimary.opacity(0.16),
                                AppColors.textPrimary.opacity(0.06),
                                .clear,
                                AppColors.base.opacity(0.20)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: AppColors.base.opacity(liftShadow ? 0.25 : 0),
                radius: liftShadow ? 12 : 0,
                y: liftShadow ? 4 : 0
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply glass surface styling with specular gleam edge highlight.
    ///
    /// - Parameters:
    ///   - radius: Corner radius (default 18pt for standard cards)
    ///   - tint: Tint color for semi-transparent fill (default white)
    ///   - strong: Use thicker fill for hover/active states (default false)
    ///   - lifted: Apply drop shadow for lifted appearance (default true)
    func glassSurface(
        radius: CGFloat = 18,
        tint: Color = AppColors.textPrimary,
        strong: Bool = false,
        lifted: Bool = true
    ) -> some View {
        modifier(GlassSurface(radius: radius, tint: tint, strong: strong, liftShadow: lifted))
    }

    /// Glass pill variant using Capsule shape instead of RoundedRectangle.
    ///
    /// - Parameters:
    ///   - strong: Use thicker fill for active states (default false)
    ///   - lifted: Apply drop shadow (default false)
    func glassPill(strong: Bool = false, lifted: Bool = false) -> some View {
        background {
            ZStack {
                Capsule()
                    .fill(.regularMaterial)
                Capsule()
                    .fill(AppColors.textPrimary.opacity(strong ? 0.10 : 0.06))
            }
        }
        .overlay {
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            AppColors.textPrimary.opacity(0.16),
                            AppColors.textPrimary.opacity(0.06),
                            .clear,
                            AppColors.base.opacity(0.20)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(
            color: AppColors.base.opacity(lifted ? 0.25 : 0),
            radius: lifted ? 12 : 0,
            y: lifted ? 4 : 0
        )
    }
}
