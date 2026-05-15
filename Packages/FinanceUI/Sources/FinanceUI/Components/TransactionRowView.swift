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
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(description)
                        .bodyLarge()
                        .lineLimit(1)

                    HStack(spacing: AppSpacing.xs) {
                        Text(date)
                            .caption()
                        Text("·")
                            .caption()
                        Text(source)
                            .caption()
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                    Text(amount)
                        .monoAmount()
                        .foregroundColor(isDebit ? AppColors.debit : AppColors.credit)

                    FBadge(isDebit ? "Debit" : "Credit", color: isDebit ? .red : .green)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)
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
