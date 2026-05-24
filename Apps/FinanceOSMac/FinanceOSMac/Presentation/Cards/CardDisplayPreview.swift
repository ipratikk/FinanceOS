import FinanceCore
import FinanceUI
import SwiftUI

struct CardDisplayPreview: View {
    let cardName: String?
    let bankName: String?
    let selectedBank: Banks?
    let cardholderName: String
    let cardNetwork: CardNetwork
    let first4: String
    let last4: String
    let bankLogo: String?

    var body: some View {
        GeometryReader { geo in
            let logoHeight = geo.size.width * 0.055
            let bankMarkSize = geo.size.width * 0.08

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
                        bankLogoView(logoHeight: logoHeight, markSize: bankMarkSize, cardWidth: geo.size.width)
                    }
                    .padding(AppSpacing.md)

                    Spacer()

                    VStack(alignment: .leading, spacing: AppSpacing.compact) {
                        if !first4.isEmpty || !last4.isEmpty {
                            HStack(spacing: 6) {
                                FDSLabel(first4.isEmpty ? "••••" : first4)
                                FDSLabel("••••  ••••")
                                FDSLabel(last4.isEmpty ? "••••" : last4)
                                Spacer()
                            }
                            .font(AppTypography.maskedAccount)
                            .foregroundStyle(Color.white)
                            .tracking(2)
                        }

                        HStack(alignment: .bottom) {
                            if !cardholderName.isEmpty {
                                FDSLabel(cardholderName.uppercased())
                                    .font(AppTypography.captionSmSemibold)
                                    .foregroundStyle(Color.white)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if let asset = cardNetwork.logoAssetName {
                                Image(asset)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: logoHeight)
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
        }
        .aspectRatio(1.586, contentMode: .fit)
    }

    @ViewBuilder
    private func bankLogoView(logoHeight: CGFloat, markSize: CGFloat, cardWidth: CGFloat) -> some View {
        if let bankLogo {
            Image(bankLogo)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: cardWidth * 0.22, maxHeight: logoHeight)
        } else if let bank = selectedBank {
            FDSBankMark(bank, size: markSize)
        }
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
