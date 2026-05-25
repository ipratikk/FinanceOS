import FinanceCore
import FinanceUI
import SwiftUI

struct CardDisplayPreview: View {
    let cardName: String?
    let cardNickName: String?
    let bankName: String?
    let selectedBank: Banks?
    let cardholderName: String
    let cardNetwork: CardNetwork
    let first4: String
    let last4: String
    let bankLogo: String?

    @State private var tilt: CGSize = .zero
    @State private var glareCenter: UnitPoint = .center
    @State private var isHovered = false

    var body: some View {
        GeometryReader { geo in
            let logoHeight = geo.size.width * 0.055
            let bankMarkSize = geo.size.width * 0.08

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(AppColors.Fill.quaternary, lineWidth: 1)
                    )

                VStack(alignment: .center, spacing: 0) {
                    HStack {
                        chipIcon
                        Spacer()
                        bankLogoView(logoHeight: logoHeight, markSize: bankMarkSize, cardWidth: geo.size.width)
                    }
                    .padding(AppSpacing.md)

                    Spacer()

                    if let cardNickName {
                        FDSLabel(cardNickName.uppercased())
                            .font(AppTypography.headlineSm)
                            .foregroundStyle(AppColors.Text.tertiaryElevated)
                            .lineLimit(1)
                    }

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
                            .foregroundStyle(AppColors.Text.primary)
                            .tracking(2)
                        }

                        HStack(alignment: .bottom) {
                            if !cardholderName.isEmpty {
                                FDSLabel(cardholderName.uppercased())
                                    .font(AppTypography.captionSmSemibold)
                                    .foregroundStyle(AppColors.Text.primary)
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

                RadialGradient(
                    colors: [Color.white.opacity(isHovered ? 0.18 : 0), .clear],
                    center: glareCenter,
                    startRadius: 0,
                    endRadius: geo.size.width * 0.7
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .blendMode(.overlay)
                .allowsHitTesting(false)
            }
            .onContinuousHover { phase in
                switch phase {
                case let .active(location):
                    let nx = (location.x / geo.size.width) - 0.5
                    let ny = (location.y / geo.size.height) - 0.5
                    withAnimation(.interactiveSpring(duration: 0.12)) {
                        tilt = CGSize(width: nx, height: ny)
                        glareCenter = UnitPoint(x: location.x / geo.size.width, y: location.y / geo.size.height)
                        isHovered = true
                    }
                case .ended:
                    withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                        tilt = .zero
                        isHovered = false
                    }
                }
            }
        }
        .aspectRatio(1.586, contentMode: .fit)
        .rotation3DEffect(.degrees(tilt.height * -14), axis: (x: 1, y: 0, z: 0), perspective: 0.4)
        .rotation3DEffect(.degrees(tilt.width * 14), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.interactiveSpring(duration: 0.12), value: tilt)
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
                    .strokeBorder(AppColors.Glass.highlight, lineWidth: 0.5)
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
