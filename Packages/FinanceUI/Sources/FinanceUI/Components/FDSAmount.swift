import FinanceCore
import SwiftUI

public enum FDSAmountType {
    case debit
    case credit
}

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

public enum FDSAmountSize {
    case normal
    case small
}

private extension View {
    func applyAmountStyle(_ size: FDSAmountSize) -> some View {
        switch size {
        case .normal:
            return AnyView(font(.system(size: 14, weight: .semibold, design: .monospaced)).lineSpacing(0))
        case .small:
            return AnyView(font(.system(size: 12, weight: .regular, design: .monospaced)).lineSpacing(0))
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
