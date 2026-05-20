import FinanceCore
import SwiftUI

/// Form field wrapper with label, optional hint, control, and optional error.
///
/// Vertical stack: label (11pt uppercase) + optional hint + control + optional error.
public struct FDSField<Content: View>: View {
    let label: String
    let hint: String?
    let error: String?
    let content: Content

    public init(
        _ label: String,
        hint: String? = nil,
        error: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.hint = hint
        self.error = error
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label.uppercased())
                    .font(AppTypography.captionSmSemibold)
                    .foregroundColor(Color(red: 0.518, green: 0.541, blue: 0.580))
                    .tracking(0.01)

                Spacer()

                if let hint {
                    Text(hint)
                        .font(AppTypography.captionSm)
                        .foregroundColor(Color(red: 0.518, green: 0.541, blue: 0.580))
                }
            }

            content

            if let error {
                Text(error)
                    .font(AppTypography.captionSm)
                    .foregroundColor(Color(red: 1.0, green: 0.27, blue: 0.23))
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        FDSField("Account Name", hint: "Required") {
            TextField("Enter name", text: .constant(""))
                .padding(10)
                .background(Color.black.opacity(0.25))
                .cornerRadius(8)
        }

        FDSField("Email", error: "Invalid email format") {
            TextField("Enter email", text: .constant(""))
                .padding(10)
                .background(Color.black.opacity(0.25))
                .cornerRadius(8)
        }
    }
    .padding()
}
