import FinanceCore
import SwiftUI

public struct FLabel: View {
    let text: String
    let icon: String?
    let color: Color

    public init(_ text: String, icon: String? = nil, color: Color = AppColors.textPrimary) {
        self.text = text
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        HStack(spacing: AppSpacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(AppTypography.bodyMdSemibold)
            }
            FDSLabel(text)
                .font(AppTypography.bodyMd)
        }
        .foregroundColor(color)
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        FLabel("Dashboard", icon: "square.grid.2x2")
        FLabel("Transactions", icon: "list.bullet")
        FLabel("Settings", icon: "gear", color: AppColors.textSecondary)
    }
    .padding()
    .background(AppColors.base)
}
