import Charts
import SwiftUI

struct TopMerchantsChart: View {
    let merchants: [(name: String, amount: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Merchants")
                .font(.system(size: 16, weight: .semibold))

            Chart(merchants, id: \.name) { item in
                BarMark(
                    x: .value("Amount", item.amount),
                    y: .value("Merchant", item.name)
                )
                .foregroundStyle(Color(red: 0.231, green: 0.510, blue: 0.980).opacity(0.7))
            }
            .frame(height: CGFloat(max(150, merchants.count * 25)))
            .chartXAxis {
                AxisMarks(format: .currency(code: "INR"))
            }
        }
        .padding(16)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .cornerRadius(10)
    }
}
