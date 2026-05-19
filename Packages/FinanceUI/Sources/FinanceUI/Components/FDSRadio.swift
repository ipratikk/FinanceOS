import FinanceCore
import SwiftUI

/// 20×20 radio button.
///
/// Off: subtle border. On: filled green accent + white dot.
public struct FDSRadio: View {
    @Binding var isSelected: Bool

    public init(isSelected: Binding<Bool>) {
        _isSelected = isSelected
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? AppColors.accent : AppColors.surface2)
                .overlay {
                    Circle()
                        .strokeBorder(
                            isSelected ? AppColors.accent : AppColors.border,
                            lineWidth: 0.5
                        )
                }

            if isSelected {
                Circle()
                    .fill(AppColors.base)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 20, height: 20)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                isSelected = true
            }
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        FDSRadio(isSelected: .constant(false))
        FDSRadio(isSelected: .constant(true))
    }
    .padding()
}
