import FinanceCore
import SwiftUI

/// Liquid Glass card container for the Finance Design System.
///
/// Uses glassSurface modifier with specular edge gleam. Owns material, gleam highlight,
/// corner radius, and drop shadow. Callers control internal padding and layout.
///
/// Usage:
/// ```swift
/// FDSCard {
///     VStack { ... }
/// }
/// ```
public struct FDSCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat
    private let padded: Bool

    public init(
        cornerRadius: CGFloat = 18,
        padded: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padded = padded
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padded ? 16 : 0)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.regularMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppColors.textPrimary.opacity(0.06))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
                color: AppColors.base.opacity(0.25),
                radius: 12,
                y: 4
            )
    }
}
