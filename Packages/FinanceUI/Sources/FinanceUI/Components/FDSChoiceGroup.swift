import SwiftUI

/// Segmented control in a capsule container.
///
/// 2–N segments. Active segment: white 0.10 fill + gleam. Spring animation.
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
                                ? Color(red: 0.945, green: 0.953, blue: 0.965)
                                : Color(red: 0.741, green: 0.761, blue: 0.800)
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background {
                            if selection == option {
                                ZStack {
                                    Capsule()
                                        .fill(.regularMaterial)
                                    Capsule()
                                        .fill(Color.white.opacity(0.10))
                                    Capsule()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.16),
                                                    Color.white.opacity(0.06),
                                                    .clear,
                                                    Color.black.opacity(0.20)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1
                                        )
                                }
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.06))
        .cornerRadius(18)
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
