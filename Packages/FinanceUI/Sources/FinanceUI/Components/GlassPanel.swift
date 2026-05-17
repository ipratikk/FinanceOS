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
            .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
    }
}

#Preview {
    GlassPanel {
        Text("Glass Panel Content")
            .headingMedium()
    }
    .padding(AppSpacing.lg)
    .background(AppColors.base)
}
