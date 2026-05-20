import FinanceCore
import SwiftUI

/// 20×20 radio button.
///
/// Off: subtle border. On: filled green accent + white dot.
public struct FDSRadio: View {
    @Binding var isSelected: Bool
    let label: String
    let isEnabled: Bool

    public init(isSelected: Binding<Bool>, label: String = "", isEnabled: Bool = true) {
        _isSelected = isSelected
        self.label = label
        self.isEnabled = isEnabled
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
                    .frame(width: AppSpacing.xs, height: AppSpacing.xs)
            }
        }
        .frame(width: 20, height: 20)
        .opacity(isEnabled ? 1.0 : 0.4)
        .disabled(!isEnabled)
        .onTapGesture {
            guard isEnabled else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                isSelected = true
            }
        }
        .accessibilityLabel(label.isEmpty ? "Radio button" : label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    HStack(spacing: 12) {
        FDSRadio(isSelected: .constant(false), label: "Option A")
        FDSRadio(isSelected: .constant(true), label: "Option B")
        FDSRadio(isSelected: .constant(false), label: "Option C (disabled)", isEnabled: false)
    }
    .padding()
}
