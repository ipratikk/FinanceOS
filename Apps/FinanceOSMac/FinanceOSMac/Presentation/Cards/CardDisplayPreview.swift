import FinanceCore
import SwiftUI

struct CardDisplayPreview: View {
    let cardName: String?
    let bankName: String?
    let cardholderName: String
    let cardNetwork: CardNetwork
    let first4: String
    let last4: String
    let bankLogo: String?

    private var networkColor: Color {
        switch cardNetwork {
        case .visa: Color(red: 0.13, green: 0.20, blue: 0.79)
        case .mastercard: Color(red: 0.92, green: 0, blue: 0.1)
        case .amex: Color(red: 0.01, green: 0.33, blue: 0.76)
        case .rupay: Color(red: 0.11, green: 0.15, blue: 0.32)
        case .discover: Color(red: 1, green: 0.6, blue: 0)
        case .diners: Color(red: 0, green: 0.51, blue: 0.73)
        case .other: AppColors.textSecondary
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
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
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            if let cardName {
                                Text(cardName)
                                    .font(AppTypography.captionSmSemibold)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        if let bankLogo {
                            Image(bankLogo)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 16)
                        }
                    }
                    .padding(AppSpacing.md)

                    Spacer()

                    VStack(alignment: .leading, spacing: AppSpacing.compact) {
                        HStack {
                            Text(!first4.isEmpty ? first4 : "••••")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white)
                            Text("•••• •••• ")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white)
                            Text(last4.isEmpty ? "••••" : last4)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .tracking(2)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cardholderName.isEmpty ? "Cardholder" : cardholderName)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(cardNetwork.displayName.uppercased())
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.white)
                                .tracking(0.5)
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
            .frame(height: 200)
        }
    }
}
