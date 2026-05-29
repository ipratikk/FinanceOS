import FinanceCore
import SwiftUI

/// Repeated placeholder skeleton rows for transaction list loading states.
///
/// Renders `count` animated rows (default 5) with a pulsing opacity animation.
/// Use `shimmer(isLoading:)` for individual element placeholders.
public struct LoadingSkeletonView: View {
    /// Number of skeleton rows to display.
    let count: Int

    public init(count: Int = 5) {
        self.count = count
    }

    public var body: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(0 ..< count, id: \.self) { _ in
                SkeletonRow()
            }
        }
    }
}

private struct SkeletonRow: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                Circle()
                    .fill(AppColors.surface2)
                    .frame(width: AppSpacing.xs, height: AppSpacing.xs)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.surface2)
                        .frame(height: 14)
                        .frame(maxWidth: 120)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.surface2)
                        .frame(height: 10)
                        .frame(maxWidth: 80)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.surface2)
                        .frame(width: 80, height: 14)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.surface2)
                        .frame(width: 50, height: 10)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Shimmer Modifier

/// Overlays a pulsing shimmer shape on any view while loading.
///
/// Hides the view's content and shows an animated placeholder in the same frame.
///
/// Usage:
/// ```swift
/// FDSLabel("Merchant name")
///     .shimmer(isLoading: isLoading)
///
/// Image(...)
///     .shimmer(isLoading: isLoading, cornerRadius: AppRadius.xl)
/// ```
public struct ShimmerModifier: ViewModifier {
    let isLoading: Bool
    let cornerRadius: CGFloat
    @State private var isAnimating = false

    public init(isLoading: Bool, cornerRadius: CGFloat = AppRadius.xs) {
        self.isLoading = isLoading
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .opacity(isLoading ? 0 : 1)
            .overlay {
                if isLoading {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppColors.surface2)
                        .opacity(isAnimating ? 0.4 : 1.0)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                                isAnimating = true
                            }
                        }
                }
            }
            .animation(AppAnimation.easeSmooth, value: isLoading)
    }
}

public extension View {
    /// Overlay a pulsing shimmer placeholder while `isLoading` is true.
    func shimmer(isLoading: Bool, cornerRadius: CGFloat = AppRadius.xs) -> some View {
        modifier(ShimmerModifier(isLoading: isLoading, cornerRadius: cornerRadius))
    }
}

#Preview {
    LoadingSkeletonView(count: 3)
        .padding(AppSpacing.lg)
        .background(AppColors.base)
}
