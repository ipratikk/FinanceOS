import FinanceCore
import SwiftUI

/// Segmented control in a capsule container.
///
/// 2–N segments. Active segment: light fill. Spring animation.
public struct FDSChoiceGroup<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
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
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button(action: { selection = option }) {
                    Text(optionLabel(option))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(
                            selection == option
                                ? AppColors.textPrimary
                                : AppColors.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background {
                            if selection == option {
                                Capsule().fill(AppColors.surface2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(AppColors.surface)
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
