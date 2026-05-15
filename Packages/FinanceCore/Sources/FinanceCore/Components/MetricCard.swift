import SwiftUI

public struct MetricCard: View {
    let label: String
    let value: String
    let delta: Delta?
    let icon: String?

    public struct Delta {
        public let change: Double
        public let period: String

        public init(change: Double, period: String) {
            self.change = change
            self.period = period
        }

        var isPositive: Bool {
            change >= 0
        }

        var text: String {
            String(format: "%+.0f%%", change)
        }
    }

    public init(_ label: String, value: String, delta: Delta? = nil, icon: String? = nil) {
        self.label = label
        self.value = value
        self.delta = delta
        self.icon = icon
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
                Text(label)
                    .headingMedium()
                Spacer()
            }

            Text(value)
                .displayMedium()

            if let delta {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: delta.isPositive ? "triangle.fill" : "triangle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .rotationEffect(.degrees(delta.isPositive ? 0 : 180))
                        .foregroundColor(delta.isPositive ? AppColors.credit : AppColors.debit)

                    Text(delta.text)
                        .caption()
                        .foregroundColor(delta.isPositive ? AppColors.credit : AppColors.debit)

                    Text("vs \(delta.period)")
                        .caption()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        MetricCard(
            "Total Debits",
            value: "₹1,24,500",
            delta: .init(change: 12, period: "last month"),
            icon: "arrow.down.circle.fill"
        )
        MetricCard(
            "Total Credits",
            value: "₹85,000",
            delta: .init(change: -5, period: "last month"),
            icon: "arrow.up.circle.fill"
        )
    }
    .padding(AppSpacing.lg)
    .background(AppColors.base)
}
