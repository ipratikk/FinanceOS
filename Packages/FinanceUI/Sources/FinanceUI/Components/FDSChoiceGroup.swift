import FinanceCore
import SwiftUI

/// Segmented control in a capsule container.
///
/// 2–N segments. Active segment: light fill. Spring animation.
public struct FDSChoiceGroup<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    /// Closure returning the button label string for each option value.
    let optionLabel: (T) -> String

    public init(
        selection: Binding<T>,
        options: [T],
        optionLabel: @escaping (T) -> String
    ) {
        _selection = selection
        self.options = options
        self.optionLabel = optionLabel
    }

    public var body: some View {
        HStack(spacing: AppSpacing.tight) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option
                FDSLiquidButton(
                    optionLabel(option),
                    variant: isSelected ? .primary : .ghost,
                    fullWidth: true,
                    action: { selection = option }
                )
            }
        }
        .padding(AppSpacing.tight)
        .background(AppColors.Glass.surface)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .strokeBorder(AppColors.Border.subtle, lineWidth: 0.5)
        )
        .cornerRadius(AppRadius.xl)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: selection)
    }
}

#Preview {
    VStack(spacing: 16) {
        FDSChoiceGroup(
            selection: .constant("visa"),
            options: ["visa", "mastercard", "amex"],
            optionLabel: { $0.uppercased() }
        )
    }
    .padding()
}
