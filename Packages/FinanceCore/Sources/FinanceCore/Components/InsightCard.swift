import SwiftUI

public struct InsightCard<Content: View>: View {
    let title: String
    let value: String
    let content: Content

    public init(_ title: String, value: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.value = value
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .caption()

                Text(value)
                    .displayMedium()
            }

            content
                .frame(height: 120)
        }
        .cardStyle()
    }
}

#Preview {
    InsightCard("Monthly Spending", value: "₹1,24,500") {
        VStack(alignment: .center) {
            Text("Chart placeholder")
                .foregroundColor(AppColors.textTertiary)
        }
    }
    .padding(AppSpacing.lg)
    .background(AppColors.base)
}
