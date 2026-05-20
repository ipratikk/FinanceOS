import FinanceCore
import SwiftUI

/// Pill-based pagination indicator.
///
/// Active dot expands to a pill; inactive dots are small circles.
/// Tap any dot to jump to that page.
///
/// Usage:
/// ```swift
/// FDSPagination(count: 4, index: $currentPage)
/// ```
public struct FDSPagination: View {
    let count: Int
    @Binding var index: Int

    public init(count: Int, index: Binding<Int>) {
        self.count = count
        _index = index
    }

    public var body: some View {
        HStack(spacing: AppSpacing.tight) {
            ForEach(0 ..< count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? AppColors.accent : AppColors.Text.quaternary.opacity(0.5))
                    .frame(width: i == index ? 18 : 6, height: 6)
                    .animation(AppAnimation.springSnappy, value: index)
                    .onTapGesture { index = i }
            }
        }
    }
}

#Preview {
    @Previewable @State var page = 0

    return VStack(spacing: AppSpacing.xl) {
        FDSPagination(count: 4, index: $page)

        HStack(spacing: AppSpacing.md) {
            Button("←") { if page > 0 { page -= 1 } }.buttonStyle(.plain)
            FDSLabel("Page \(page + 1) of 4")
            Button("→") { if page < 3 { page += 1 } }.buttonStyle(.plain)
        }
        .font(AppTypography.bodySm)
        .foregroundStyle(AppColors.Text.secondary)
    }
    .padding(AppSpacing.xl)
    .background(AppColors.base)
}
