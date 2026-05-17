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
            .shadow(color: .black.opacity(AppShadow.cardOpacity), radius: AppShadow.cardRadius / 2, y: 2)
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        FinanceCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Account Balance")
                    .headingMedium()
                HStack {
                    Text("HDFC Savings")
                        .bodyMedium()
                    Spacer()
                    Text("₹1,24,500")
                        .monoAmount()
                }
            }
        }

        FinanceCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Recent Transaction")
                    .headingMedium()
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("Swiggy")
                            .bodyLarge()
                        Text("Today at 2:30 PM")
                            .caption()
                    }
                    Spacer()
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(AppColors.debit)
                        Text("₹320")
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
