import FinanceCore
import SwiftUI

/// Card network logos (Visa, Mastercard, Amex, Diners, RuPay).
///
/// Simplified SwiftUI renders. Used in card displays and hero previews.
public struct FDSNetworkLogo: View {
    let network: CardNetwork

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
            Text(network.displayName)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var visaLogo: some View {
        Text("VISA")
            .font(.system(size: 10, weight: .bold, design: .default))
            .italic()
            .foregroundColor(.white)
            .tracking(-0.02)
    }

    private var mastercardLogo: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(Color(red: 1.0, green: 0.27, blue: 0.23))
                .frame(width: 10, height: 10)

            Circle()
                .fill(Color(red: 1.0, green: 0.62, blue: 0.04))
                .frame(width: 10, height: 10)
        }
        .frame(width: 20, height: 10)
    }

    private var amexLogo: some View {
        VStack(spacing: 0.5) {
            Text("AMERICAN")
                .font(.system(size: 6, weight: .semibold))
            Text("EXPRESS")
                .font(.system(size: 6, weight: .semibold))
        }
        .foregroundColor(.white)
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
            Text("Ru")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(Color(red: 0.19, green: 0.82, blue: 0.35))
            Text("Pay")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(Color(red: 1.0, green: 0.62, blue: 0.04))
        }
    }
}

extension CardNetwork {
    public var displayName: String {
        switch self {
        case .visa: "Visa"
        case .mastercard: "Mastercard"
        case .amex: "American Express"
        case .discover: "Discover"
        case .diners: "Diners Club"
        case .rupay: "RuPay"
        case .other: "Other"
        }
    }
}
