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
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(isHovered ? 0.10 : 0.05), lineWidth: 0.5)
                    }
            }
            .onHover { isHovered = $0 }
    }
}
