import FinanceCore
import SwiftUI

/// Visual-first transaction row.
///
/// Layout:
/// ```
/// [merchant avatar]  Merchant Name             ₹65.43
///                    Category · 12:30 PM     [Chip]
/// ```
///
/// Replaces text-heavy old TransactionRowView. Information-dense,
/// scannable, logo/symbol-driven.
public struct FDSTransactionRow: View {
    let merchant: String
    let categorySymbol: String?
    let merchantLogo: String?
    let subtitle: String
    let amount: String
    let isDebit: Bool
    let accountChip: AccountChipData?

    public struct AccountChipData {
        public let bankName: String
        public let last4: String
        public let logoName: String?

        public init(bankName: String, last4: String, logoName: String? = nil) {
            self.bankName = bankName
            self.last4 = last4
            self.logoName = logoName
        }
    }

    public init(
        merchant: String,
        categorySymbol: String? = nil,
        merchantLogo: String? = nil,
        subtitle: String,
        amount: String,
        isDebit: Bool,
        accountChip: AccountChipData? = nil
    ) {
        self.merchant = merchant
        self.categorySymbol = categorySymbol
        self.merchantLogo = merchantLogo
        self.subtitle = subtitle
        self.amount = amount
        self.isDebit = isDebit
        self.accountChip = accountChip
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            FDSMerchantAvatar(
                name: merchant,
                symbol: categorySymbol ?? "creditcard.fill",
                imageName: merchantLogo,
                size: 36
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(merchant)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: AppSpacing.md)

            VStack(alignment: .trailing, spacing: 2) {
                Text(amount)
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(isDebit ? .primary : AppColors.credit)
                    .lineLimit(1)

                if let chip = accountChip {
                    HStack(spacing: 3) {
                        Text(chip.bankName)
                            .font(.system(size: 10, weight: .medium))
                        Text("· \(chip.last4)")
                            .font(.system(size: 10, weight: .regular).monospacedDigit())
                    }
                    .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, AppSpacing.compact)
        .padding(.horizontal, AppSpacing.md)
        .contentShape(Rectangle())
    }
}
