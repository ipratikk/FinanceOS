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
                    .fill(AppColors.surface.opacity(0.5))
                    .background(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppColors.accentCyan.opacity(isHovered ? 0.25 : 0.15),
                                        AppColors.accentCyan.opacity(isHovered ? 0.15 : 0.08)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
            }
            .shadow(
                color: AppColors.accentCyan.opacity(isHovered ? 0.15 : 0.05),
                radius: isHovered ? 16 : 8,
                x: 0,
                y: isHovered ? 8 : 4
            )
            .onHover { isHovered = $0 }
    }
}
