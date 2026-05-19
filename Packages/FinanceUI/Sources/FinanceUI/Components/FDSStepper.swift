import SwiftUI

/// Day-of-month stepper with − | value | + controls.
///
/// Used for statement day and due day selection (1-31).
public struct FDSStepper: View {
    @Binding var value: Int
    let label: String
    let min: Int
    let max: Int

    public init(
        _ label: String,
        value: Binding<Int>,
        min: Int = 1,
        max: Int = 31
    ) {
        self.label = label
        self._value = value
        self.min = min
        self.max = max
    }

    public var body: some View {
        HStack(spacing: 0) {
            Button(action: { if value > min { value -= 1 } }) {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Text(String(format: "%02d", value))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                .frame(maxWidth: .infinity)
                .frame(height: 32)

            Button(action: { if value < max { value += 1 } }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .background(Color.black.opacity(0.25))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 16) {
        FDSStepper("Statement Day", value: .constant(15))
        FDSStepper("Due Day", value: .constant(5))
    }
    .padding()
}
