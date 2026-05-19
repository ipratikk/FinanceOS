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
        self._selection = selection
        self.options = options
        self.optionLabel = optionLabel
    }

    public var body: some View {
        HStack(spacing: 12) {
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(optionLabel(option))
                        .tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.518, green: 0.541, blue: 0.580))
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(Color.black.opacity(0.25))
        .cornerRadius(8)
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
