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
        cornerRadius: CGFloat = AppRadius.lg,
        padded: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padded = padded
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padded ? AppSpacing.md : 0)
            .glassSurface(radius: cornerRadius)
    }
}
