import FinanceCore
import SwiftUI

public struct GlassPanel<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(AppSpacing.md)
            .background(
                ZStack {
                    AppColors.surface2.opacity(0.5)
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColors.borderAccent.opacity(0.3), lineWidth: 1)
                }
            )
            .cornerRadius(AppRadius.md)
            .shadow(
                color: AppShadows.standard.color,
                radius: AppShadows.standard.radius,
                x: AppShadows.standard.offsetX,
                y: AppShadows.standard.offsetY
            )
    }
}

#Preview {
    GlassPanel {
        FDSLabel("Glass Panel Content")
            .font(AppTypography.headingMd).foregroundColor(AppColors.Text.primary)
    }
    .padding(AppSpacing.lg)
    .background(AppColors.base)
}
