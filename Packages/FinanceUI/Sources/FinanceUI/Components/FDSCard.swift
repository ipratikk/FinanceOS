import FinanceCore
import SwiftUI

/// Structural glass card container for the Finance Design System.
///
/// Owns: material, border, corner radius, hover border brightening.
/// Callers control internal padding and content layout.
///
/// Usage:
/// ```swift
/// FDSCard {
///     VStack { ... }
///         .padding(AppSpacing.lg)
/// }
/// ```
public struct FDSCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat

    @State private var isHovered = false

    public init(cornerRadius: CGFloat = AppRadius.lg, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(AppColors.surface.opacity(0.4))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                AppColors.accentGold.opacity(isHovered ? 0.15 : 0.08),
                                lineWidth: 0.5
                            )
                    }
            }
            .shadow(
                color: Color.black.opacity(isHovered ? 0.2 : 0.1),
                radius: isHovered ? 12 : 8,
                x: 0,
                y: isHovered ? 4 : 2
            )
            .onHover { isHovered = $0 }
    }
}
