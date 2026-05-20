import FinanceCore
import SwiftUI

public struct FinanceCard<Content: View>: View {
    let content: Content
    let padding: CGFloat

    public init(padding: CGFloat = AppSpacing.md, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)
            .shadow(
                color: AppShadows.standard.color,
                radius: AppShadows.standard.radius,
                x: AppShadows.standard.x,
                y: AppShadows.standard.y
            )
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        FinanceCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                FDSLabel("Account Balance")
                    .headingMedium()
                HStack {
                    FDSLabel("HDFC Savings")
                        .bodyMedium()
                    Spacer()
                    FDSLabel("₹1,24,500")
                        .monoAmount()
                }
            }
        }

        FinanceCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                FDSLabel("Recent Transaction")
                    .headingMedium()
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        FDSLabel("Swiggy")
                            .bodyLarge()
                        FDSLabel("Today at 2:30 PM")
                            .caption()
                    }
                    Spacer()
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(AppColors.debit)
                        FDSLabel("₹320")
                            .monoAmount()
                            .foregroundColor(AppColors.debit)
                    }
                }
            }
        }
    }
    .padding(AppSpacing.lg)
    .background(AppColors.base)
}
