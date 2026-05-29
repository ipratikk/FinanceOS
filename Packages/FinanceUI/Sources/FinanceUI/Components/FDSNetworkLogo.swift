import FinanceCore
import SwiftUI

/// Card network logos (Visa, Mastercard, Amex, Diners, RuPay).
///
/// Simplified SwiftUI renders. Used in card displays and hero previews.
public struct FDSNetworkLogo: View {
    let network: CardNetwork

    /// - Parameter network: Card network enum value. Unknown networks render as a text label.
    public init(_ network: CardNetwork) {
        self.network = network
    }

    public var body: some View {
        switch network {
        case .visa:
            visaLogo
        case .mastercard:
            mastercardLogo
        case .amex:
            amexLogo
        case .diners:
            dinersLogo
        case .rupay:
            rupayLogo
        default:
            FDSLabel(network.displayName)
                .font(AppTypography.captionSmSemibold)
                .foregroundColor(AppColors.textPrimary)
        }
    }

    private var visaLogo: some View {
        FDSLabel("VISA")
            .font(AppTypography.captionSmSemibold)
            .italic()
            .foregroundColor(AppColors.textPrimary)
            .tracking(-0.02)
    }

    private var mastercardLogo: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(AppColors.danger)
                .frame(width: 10, height: 10)

            Circle()
                .fill(AppColors.accent)
                .frame(width: 10, height: 10)
        }
        .frame(width: 20, height: 10)
    }

    private var amexLogo: some View {
        VStack(spacing: 0.5) {
            FDSLabel("AMERICAN")
                .font(AppTypography.captionSmSemibold)
            FDSLabel("EXPRESS")
                .font(AppTypography.captionSmSemibold)
        }
        .foregroundColor(AppColors.textPrimary)
        .tracking(0.01)
    }

    private var dinersLogo: some View {
        HStack(spacing: 1) {
            Circle()
                .fill(Color(red: 0.0, green: 0.471, blue: 0.753))
                .frame(width: 8, height: 8)

            Circle()
                .stroke(Color(red: 0.0, green: 0.471, blue: 0.753), lineWidth: 1)
                .frame(width: 8, height: 8)
        }
    }

    private var rupayLogo: some View {
        HStack(spacing: 1) {
            FDSLabel("Ru")
                .font(AppTypography.captionSmSemibold)
                .foregroundColor(AppColors.accent)
            FDSLabel("Pay")
                .font(AppTypography.captionSmSemibold)
                .foregroundColor(AppColors.accent)
        }
    }
}
