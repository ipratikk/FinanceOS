import SwiftUI

public struct LoadingSkeletonView: View {
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
                    .frame(width: 8, height: 8)

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

#Preview {
    LoadingSkeletonView(count: 3)
        .padding(AppSpacing.lg)
        .background(AppColors.base)
}
