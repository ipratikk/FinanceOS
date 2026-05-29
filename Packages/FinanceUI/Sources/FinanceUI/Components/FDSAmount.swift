import FinanceCore
import SwiftUI

/// Semantic type for an amount — determines red/green coloring.
public enum FDSAmountType {
    case debit
    case credit
}

/// Pre-formatted amount label with semantic debit/credit color.
///
/// Accepts a pre-formatted string (e.g. "+₹1,500.00"). Use `FAmount` for raw minor-unit input.
public struct FDSAmount: View {
    let text: String
    let type: FDSAmountType
    let size: FDSAmountSize

    public var body: some View {
        Text(text)
            .applyAmountStyle(size)
            .foregroundColor(type == .debit ? AppColors.debit : AppColors.credit)
    }

    public init(_ text: String, type: FDSAmountType, size: FDSAmountSize = .normal) {
        self.text = text
        self.type = type
        self.size = size
    }
}

/// Display size for `FDSAmount`. Normal maps to `amountSm`; small maps to `amountXs`.
public enum FDSAmountSize {
    case normal
    case small
}

private extension View {
    func applyAmountStyle(_ size: FDSAmountSize) -> some View {
        switch size {
        case .normal:
            return AnyView(font(AppTypography.amountSm.weight(.semibold)).lineSpacing(0))
        case .small:
            return AnyView(font(AppTypography.amountXs).lineSpacing(0))
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        FDSAmount("+INR 5000.00", type: .credit, size: .normal)
        FDSAmount("-INR 350.50", type: .debit, size: .normal)
        FDSAmount("+INR 100.00", type: .credit, size: .small)
        FDSAmount("-INR 50.00", type: .debit, size: .small)
    }
    .padding()
}
