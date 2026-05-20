import FinanceCore
import SwiftUI

/// Transaction row cell with merchant logo, running balance, and account chip.
/// Designed for list and custom containers.
///
/// Layout:
/// ```
/// [merchant avatar]  Merchant Name             ₹65.43
///                    Category · 12:30 PM     [Chip / Balance]
/// ```
///
/// Replaces text-heavy TransactionRowView. Information-dense,
/// scannable, logo/symbol-driven.
public struct FDSTransactionRow: View {
    let merchant: String
    let categorySymbol: String?
    let merchantLogo: String?
    let subtitle: String
    let amount: String
    let isDebit: Bool
    let accountChip: AccountChipData?
    let runningBalance: String?
    let onTap: (() -> Void)?

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
        accountChip: AccountChipData? = nil,
        runningBalance: String? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.merchant = merchant
        self.categorySymbol = categorySymbol
        self.merchantLogo = merchantLogo
        self.subtitle = subtitle
        self.amount = amount
        self.isDebit = isDebit
        self.accountChip = accountChip
        self.runningBalance = runningBalance
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: { onTap?() }, label: { rowContent })
            .buttonStyle(.plain)
            .disabled(onTap == nil)
    }

    private var rowContent: some View {
        HStack(spacing: AppSpacing.md) {
            FDSMerchantAvatar(
                name: merchant,
                symbol: categorySymbol ?? "creditcard.fill",
                imageName: merchantLogo,
                size: 36
            )

            VStack(alignment: .leading, spacing: 2) {
                FDSLabel(merchant)
                    .font(AppTypography.bodySmMedium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                FDSLabel(subtitle)
                    .font(AppTypography.captionSm)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: AppSpacing.md)

            VStack(alignment: .trailing, spacing: 2) {
                FDSLabel(amount)
                    .font(AppTypography.bodySmMedium.monospacedDigit())
                    .foregroundStyle(isDebit ? AppColors.debit : AppColors.credit)
                    .lineLimit(1)

                if let balance = runningBalance {
                    FDSLabel(balance)
                        .font(AppTypography.captionSm.monospacedDigit())
                        .foregroundStyle(.tertiary)
                } else if let chip = accountChip {
                    HStack(spacing: 3) {
                        FDSLabel(chip.bankName)
                            .font(AppTypography.captionSmSemibold)
                        FDSLabel("· \(chip.last4)")
                            .font(AppTypography.captionSm.monospacedDigit())
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
