import Charts
import FinanceCore
import SwiftUI

struct SpendingTrendChart: View {
    let monthlySummaries: [MonthlySpendingSummary]

    private struct ChartDataPoint {
        let date: Date
        let debit: Double
        let credit: Double
    }

    private var chartData: [ChartDataPoint] {
        monthlySummaries.map { summary in
            ChartDataPoint(
                date: summary.id,
                debit: Double(summary.totalDebit) / 100.0,
                credit: Double(summary.totalCredit) / 100.0
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Trend")
                .font(.system(size: 16, weight: .semibold))

            Chart(chartData, id: \.date) { item in
                BarMark(
                    x: .value("Month", item.date, unit: .month),
                    y: .value("Debits", item.debit)
                )
                .foregroundStyle(Color.red.opacity(0.7))
                .position(by: .value("Type", "Debits"))

                BarMark(
                    x: .value("Month", item.date, unit: .month),
                    y: .value("Credits", item.credit)
                )
                .foregroundStyle(Color.green.opacity(0.7))
                .position(by: .value("Type", "Credits"))
            }
            .frame(height: 200)
            .chartLegend(position: .bottom)
            .chartXAxis {
                AxisMarks(format: .dateTime.month(.abbreviated))
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .cornerRadius(10)
    }
}
