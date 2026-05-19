import FinanceCore
import SwiftUI

/// Dropdown select field styled like FDSInput.
///
/// Wraps native Picker with .menu style. Same chrome as text input.
public struct FDSSelect<T: Hashable>: View {
    let label: String
    @Binding var selection: T
    let options: [T]
    let optionLabel: (T) -> String

    public init(
        _ label: String,
        selection: Binding<T>,
        options: [T],
        optionLabel: @escaping (T) -> String
    ) {
        self.label = label
        _selection = selection
        self.options = options
        self.optionLabel = optionLabel
    }

    public var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(optionLabel(option)) {
                    selection = option
                }
            }
        } label: {
            HStack(spacing: 12) {
                Text(optionLabel(selection))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(AppColors.surface2)
            .cornerRadius(8)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        FDSSelect(
            "Account Type",
            selection: .constant("savings"),
            options: ["savings", "current", "salary"],
            optionLabel: { $0.capitalized }
        )
    }
    .padding()
}
