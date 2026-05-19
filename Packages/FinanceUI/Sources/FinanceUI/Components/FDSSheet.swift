import SwiftUI

/// Modal sheet primitive for edit flows.
///
/// Backdrop: black 35% + ultraThinMaterial blur. Sheet: glass surface with gleam,
/// header (title + close X), scrollable body, footer (destructive + cancel + primary).
/// Animation: scale 0.985 + opacity fade-in. Escape key + backdrop click dismiss.
public struct FDSSheet<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    public init(
        title: String,
        subtitle: String? = nil,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                    onDismiss()
                }

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))

                        if let subtitle {
                            Text(subtitle)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                        }
                    }

                    Spacer()

                    Button(action: {
                        dismiss()
                        onDismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.518, green: 0.541, blue: 0.580))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(Color.black.opacity(0.15))

                Divider()
                    .opacity(0.2)

                ScrollView {
                    content
                        .padding(20)
                }

                Divider()
                    .opacity(0.2)

                HStack(spacing: 12) {
                    Spacer()

                    Button(action: {
                        dismiss()
                        onDismiss()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                            .frame(minWidth: 80)
                            .frame(height: 32)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(Color.black.opacity(0.1))
            }
            .frame(maxWidth: 580)
            .frame(maxHeight: .infinity)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.thickMaterial)

                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
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
            .shadow(color: .black.opacity(0.30), radius: 32, y: 16)
            .scaleEffect(0.985)
            .opacity(0.95)
            .transition(.scale(scale: 0.985).combined(with: .opacity))
            .animation(.timingCurve(0.18, 0.70, 0.30, 1.0, duration: 0.22), value: UUID())
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.039, green: 0.047, blue: 0.067)
            .ignoresSafeArea()

        FDSSheet(
            title: "Edit Account",
            subtitle: "Update account details",
            onDismiss: {}
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Account Name")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                TextField("Enter name", text: .constant(""))
                    .padding(10)
                    .background(Color.black.opacity(0.25))
                    .cornerRadius(8)
            }
        }
    }
}
