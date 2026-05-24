import FinanceCore
import FinanceUI
import SwiftUI

struct CardDisplayPreview: View {
    let cardName: String?
    let bankName: String?
    let cardholderName: String
    let cardNetwork: CardNetwork
    let first4: String
    let last4: String
    let bankLogo: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    chipIcon
                    Spacer()
                    Image(systemName: "wave.3.right.circle")
                        .font(.system(size: 20, weight: .ultraLight))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
                .padding(AppSpacing.md)

                Spacer()

                VStack(alignment: .leading, spacing: AppSpacing.compact) {
                    HStack(spacing: 6) {
                        FDSLabel(first4.isEmpty ? "XXXX" : first4)
                        FDSLabel("••••  ••••")
                        FDSLabel(last4.isEmpty ? "XXXX" : last4)
                        Spacer()
                    }
                    .font(AppTypography.maskedAccount)
                    .foregroundStyle(Color.white)
                    .tracking(2)

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            FDSLabel("CARD HOLDER")
                                .font(AppTypography.captionSm)
                                .foregroundStyle(Color.white.opacity(0.5))
                                .tracking(0.5)
                            FDSLabel(cardholderName.isEmpty ? "YOUR NAME" : cardholderName.uppercased())
                                .font(AppTypography.captionSmSemibold)
                                .foregroundStyle(Color.white)
                                .lineLimit(1)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            FDSLabel("INSTITUTION")
                                .font(AppTypography.captionSm)
                                .foregroundStyle(Color.white.opacity(0.5))
                                .tracking(0.5)
                            FDSLabel(institutionLabel.uppercased())
                                .font(AppTypography.captionSmSemibold)
                                .foregroundStyle(Color.white)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
        }
    }

    private var institutionLabel: String {
        if let bankName, !bankName.isEmpty { return bankName }
        return cardNetwork == .other ? "Other" : cardNetwork.displayName
    }

    private var chipIcon: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.85, green: 0.71, blue: 0.37),
                        Color(red: 0.65, green: 0.52, blue: 0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 32, height: 24)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
            )
    }

    private var cardGradient: LinearGradient {
        switch cardNetwork {
        case .visa:
            return LinearGradient(
                colors: [Color(red: 0.08, green: 0.15, blue: 0.53), Color(red: 0.05, green: 0.10, blue: 0.37)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .mastercard:
            return LinearGradient(
                colors: [Color(red: 0.55, green: 0.05, blue: 0.05), Color(red: 0.35, green: 0.02, blue: 0.02)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .amex:
            return LinearGradient(
                colors: [Color(red: 0.01, green: 0.25, blue: 0.55), Color(red: 0.01, green: 0.16, blue: 0.38)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .rupay:
            return LinearGradient(
                colors: [Color(red: 0.08, green: 0.12, blue: 0.25), Color(red: 0.05, green: 0.08, blue: 0.18)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .discover:
            return LinearGradient(
                colors: [Color(red: 0.70, green: 0.40, blue: 0.0), Color(red: 0.50, green: 0.28, blue: 0.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .diners:
            return LinearGradient(
                colors: [Color(red: 0.0, green: 0.35, blue: 0.50), Color(red: 0.0, green: 0.22, blue: 0.33)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .other:
            return LinearGradient(
                colors: [Color(red: 0.10, green: 0.12, blue: 0.16), Color(red: 0.06, green: 0.07, blue: 0.10)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}
