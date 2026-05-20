import FinanceCore
import SwiftUI

/// 76×48 mini credit card render for display in rows.
///
/// Shows gradient background, gold chip (top-left), network short (top-right),
/// and masked card number (bottom-left). Includes gleam edge highlight.
public struct FDSCardArt: View {
    let cardName: String
    let network: String
    let last4: String
    let gradientStart: Color
    let gradientEnd: Color

    public init(
        _ cardName: String,
        network: String = "VISA",
        last4: String = "1234",
        gradientStart: Color = Color(red: 0.0, green: 0.2, blue: 0.6),
        gradientEnd: Color = Color(red: 0.0, green: 0.3, blue: 0.8)
    ) {
        self.cardName = cardName
        self.network = network
        self.last4 = last4
        self.gradientStart = gradientStart
        self.gradientEnd = gradientEnd
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [gradientStart, gradientEnd]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.System.yellow)
                        .frame(width: 12, height: 9)

                    Spacer()

                    FDSLabel(network)
                        .font(AppTypography.captionSmSemibold)
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding(AppSpacing.tight)

                Spacer()

                HStack {
                    FDSLabel("•• \(last4)")
                        .font(AppTypography.captionSmSemibold)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()
                }
                .padding(AppSpacing.tight)
            }

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            AppColors.textPrimary.opacity(0.16),
                            AppColors.textPrimary.opacity(0.06),
                            .clear,
                            AppColors.base.opacity(0.20)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .frame(width: 76, height: 48)
        .cornerRadius(AppRadius.sm)
        .shadow(
            color: AppShadows.subtle.color,
            radius: AppShadows.subtle.radius,
            x: AppShadows.subtle.x,
            y: AppShadows.subtle.y
        )
    }
}

#Preview {
    HStack(spacing: 12) {
        FDSCardArt("HDFC Visa", network: "VISA", last4: "1234")
        FDSCardArt(
            "ICICI Mastercard",
            network: "MC",
            last4: "5678",
            gradientStart: Color(red: 0.8, green: 0.2, blue: 0),
            gradientEnd: Color(red: 1.0, green: 0.4, blue: 0)
        )
        FDSCardArt(
            "Amex Platinum",
            network: "AMEX",
            last4: "9999",
            gradientStart: Color(red: 0.0, green: 0.2, blue: 0.5),
            gradientEnd: Color(red: 0.0, green: 0.4, blue: 0.7)
        )
    }
    .padding()
}
