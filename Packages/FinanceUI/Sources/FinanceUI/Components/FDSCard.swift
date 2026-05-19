import FinanceCore
import SwiftUI

/// Flat card container for the Finance Design System.
///
/// Clean, minimal design with subtle border. No glass effects or shadows.
/// Callers control internal padding and layout.
public struct FDSCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat
    private let padded: Bool

    public init(
        cornerRadius: CGFloat = 12,
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
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.surface2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppColors.border, lineWidth: 0.5)
            }
    }
}
