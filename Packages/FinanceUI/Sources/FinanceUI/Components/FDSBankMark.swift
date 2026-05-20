import FinanceCore
import SwiftUI

/// 36×36 bank identification mark with short code and tint.
///
/// Displays bank short code (3–5 chars) in white on colored rounded square background.
/// Includes specular gleam edge highlight.
public struct FDSBankMark: View {
    let bank: Banks
    let size: CGFloat

    public init(_ bank: Banks, size: CGFloat = 36) {
        self.bank = bank
        self.size = size
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .fill(bank.tintColor.opacity(0.2))

            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .strokeBorder(bank.tintColor.opacity(0.3), lineWidth: 0.5)

            FDSLabel(bank.shortCode)
                .font(.system(size: size * 0.4, weight: .semibold, design: .default))
                .foregroundColor(bank.tintColor)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 16) {
        FDSBankMark(.hdfc)
        FDSBankMark(.icici)
        FDSBankMark(.amex)
        FDSBankMark(.scapia)
    }
    .padding()
}
