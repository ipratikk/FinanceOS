import Charts
import FinanceCore
import FinanceUI
import SwiftUI

struct TopMerchantsChart: View {
    let merchants: [(name: String, amount: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FDSLabel("Top Merchants")
                .headingSmall()

            Chart(merchants, id: \.name) { item in
                BarMark(
                    x: .value("Amount", item.amount),
                    y: .value("Merchant", item.name)
                )
                .foregroundStyle(AppColors.accent.opacity(0.7))
            }
            .frame(height: CGFloat(max(150, merchants.count * 25)))
            .chartXAxis {
                AxisMarks(format: .currency(code: "INR"))
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }
}
