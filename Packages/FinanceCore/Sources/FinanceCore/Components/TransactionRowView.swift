import SwiftUI

public struct TransactionRowView: View {
    let description: String
    let amount: String
    let date: String
    let source: String
    let isDebit: Bool
    let onTap: (() -> Void)?

    public init(
        description: String,
        amount: String,
        date: String,
        source: String,
        isDebit: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.description = description
        self.amount = amount
        self.date = date
        self.source = source
        self.isDebit = isDebit
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: AppSpacing.md) {
                Circle()
                    .fill(isDebit ? AppColors.debit : AppColors.credit)
                    .frame(width: 6, height: 6)

                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(description)
                        .bodyMedium()
                        .lineLimit(1)

                    HStack(spacing: AppSpacing.xxs) {
                        Text(date)
                            .caption()
                        Text("·")
                            .caption()
                        Text(source)
                            .caption()
                    }
                    .foregroundColor(AppColors.textTertiary)
                }

                Spacer()

                Text(amount)
                    .monoAmount()
                    .foregroundColor(isDebit ? AppColors.debit : AppColors.credit)
            }
            .padding(AppSpacing.sm)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        TransactionRowView(
            description: "Swiggy",
            amount: "₹320.00",
            date: "Apr 23",
            source: "ICICI Card ••••1234",
            isDebit: true
        )

        TransactionRowView(
            description: "Salary Credit",
            amount: "₹85,000.00",
            date: "Apr 1",
            source: "HDFC Savings ••••6521",
            isDebit: false
        )
    }
    .padding(AppSpacing.lg)
    .background(AppColors.base)
}
