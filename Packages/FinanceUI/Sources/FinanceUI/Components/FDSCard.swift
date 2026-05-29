import FinanceCore
import SwiftUI

/// Liquid Glass card container.
///
/// By default uses the native macOS 26 `glassEffect` (Liquid Glass), which reflects
/// the desktop wallpaper. Pass `glass: false` for a flat material surface with no
/// environmental bleed.
///
/// Usage:
/// ```swift
/// FDSCard { VStack { ... } }                  // glass (default)
/// FDSCard(glass: false) { VStack { ... } }    // flat material
/// ```
public struct FDSCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat
    private let padded: Bool
    private let glass: Bool

    public init(
        /// Corner radius applied to the card shape. Defaults to `AppRadius.lg` (16pt).
        cornerRadius: CGFloat = AppRadius.lg,
        /// When false, no internal padding is applied (content fills edge to edge).
        padded: Bool = true,
        /// When true, applies native Liquid Glass effect; when false, uses flat `AppColors.Glass.surface`.
        glass: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padded = padded
        self.glass = glass
        self.content = content()
    }

    public var body: some View {
        if glass {
            content
                .padding(padded ? AppSpacing.md : 0)
                .glassSurface(radius: cornerRadius)
        } else {
            content
                .padding(padded ? AppSpacing.md : 0)
                .background(AppColors.Glass.surface)
                .cornerRadius(cornerRadius)
        }
    }
}
