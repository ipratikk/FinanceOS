import FinanceCore
import SwiftUI

/// Monospaced currency amount primitive that formats minor units (Int64) via `FormatterCache`.
///
/// Handles INR, USD, EUR. Use `FDSAmount` when you already have a formatted string.
public struct FAmount: View {
    /// Amount in minor units (e.g. paise for INR, cents for USD).
    let amountMinorUnits: Int64
    let currencyCode: String
    /// Determines red (debit) or green (credit) text color.
    let isDebit: Bool
    let size: Size

    /// Typography size for the amount. Large = 16pt semibold, Medium = 14pt, Small = 12pt regular.
    public enum Size {
        case large
        case medium
        case small
    }

    public init(_ amountMinorUnits: Int64, currency: String, isDebit: Bool = false, size: Size = .medium) {
        self.amountMinorUnits = amountMinorUnits
        currencyCode = currency
        self.isDebit = isDebit
        self.size = size
    }

    var formattedAmount: String {
        FormatterCache.formatCurrency(minorUnits: amountMinorUnits, currencyCode: currencyCode)
    }

    var textColor: Color {
        isDebit ? AppColors.debit : AppColors.credit
    }

    public var body: some View {
        Text(formattedAmount)
            .font(font)
            .foregroundColor(textColor)
    }

    var font: Font {
        switch size {
        case .large:
            return .system(size: 16, weight: .semibold, design: .monospaced)
        case .medium:
            return .system(size: 14, weight: .semibold, design: .monospaced)
        case .small:
            return .system(size: 12, weight: .regular, design: .monospaced)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        FAmount(124_500, currency: "INR", isDebit: true, size: .large)
        FAmount(85000, currency: "INR", isDebit: false, size: .medium)
        FAmount(320, currency: "INR", isDebit: true, size: .small)
    }
    .padding()
    .background(AppColors.base)
}
