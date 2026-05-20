import FinanceCore
import SwiftUI

public struct FDSCreditCardDisplay: View {
    let cardName: String?
    let bankName: String?
    let cardNetwork: String
    @Binding var encryptedCardNumber: String
    @Binding var last4: String

    public init(
        cardName: String? = nil,
        bankName: String? = nil,
        cardNetwork: String,
        encryptedCardNumber: Binding<String>,
        last4: Binding<String>
    ) {
        self.cardName = cardName
        self.bankName = bankName
        self.cardNetwork = cardNetwork
        _encryptedCardNumber = encryptedCardNumber
        _last4 = last4
    }

    private var networkColor: Color {
        switch cardNetwork.lowercased() {
        case "visa": return Color(red: 0.13, green: 0.20, blue: 0.79)
        case "mastercard": return Color(red: 0.92, green: 0, blue: 0.1)
        case "amex": return Color(red: 0.01, green: 0.33, blue: 0.76)
        case "rupay": return Color(red: 0.11, green: 0.15, blue: 0.32)
        case "discover": return Color(red: 1, green: 0.6, blue: 0)
        case "diners": return Color(red: 0, green: 0.51, blue: 0.73)
        default: return AppColors.textSecondary
        }
    }

    private var maskedCardNumber: String {
        guard !encryptedCardNumber.isEmpty else { return "•••• •••• •••• ••••" }
        let lastFour = String(encryptedCardNumber.suffix(4))
        return "•••• •••• •••• \(lastFour)"
    }

    public var body: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                networkColor.opacity(0.8),
                                networkColor.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(AppColors.textPrimary.opacity(0.2), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            if let cardName {
                                FDSLabel(cardName)
                                    .font(AppTypography.captionSmSemibold)
                                    .foregroundStyle(AppColors.textPrimary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        if let bankName {
                            FDSLabel(bankName)
                                .font(AppTypography.captionSm)
                                .foregroundStyle(AppColors.textPrimary.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                    .padding(AppSpacing.md)

                    Spacer()

                    VStack(alignment: .leading, spacing: AppSpacing.compact) {
                        FDSLabel(maskedCardNumber)
                            .font(AppTypography.amountXs)
                            .foregroundStyle(AppColors.textPrimary)
                            .tracking(2)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                if let cardName {
                                    FDSLabel(cardName)
                                        .font(AppTypography.captionSmSemibold)
                                        .foregroundStyle(AppColors.textPrimary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            FDSLabel(cardNetwork.uppercased())
                                .font(AppTypography.captionSmSemibold)
                                .foregroundStyle(AppColors.textPrimary)
                                .tracking(0.5)
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
            .frame(height: 200)

            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                FDSLabel("Encrypted Card Number")
                    .font(AppTypography.captionSmSemibold)
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)
                FDSTextInput("e.g. 4532123456789010", text: $encryptedCardNumber)
            }

            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                FDSLabel("Last 4 Digits")
                    .font(AppTypography.captionSmSemibold)
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)
                FDSTextInput("Last 4", text: $last4)
                    .onChange(of: last4) { _, value in
                        if value.count > 4 { last4 = String(value.prefix(4)) }
                    }
            }
        }
    }
}
