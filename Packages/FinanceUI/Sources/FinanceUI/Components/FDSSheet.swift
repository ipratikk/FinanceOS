import FinanceCore
import SwiftUI

/// Modal sheet primitive for edit flows.
///
/// Backdrop: black 35%. Sheet: flat dark surface with border,
/// header (title + close X), scrollable body, footer (cancel + primary).
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
                            .font(DesignTokens.Typography.sheetTitle)
                            .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))

                        if let subtitle {
                            Text(subtitle)
                                .font(AppTypography.bodySm)
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
                .padding(AppSpacing.lg)
                .background(Color.black.opacity(0.15))

                Divider()
                    .opacity(0.2)

                ScrollView {
                    content
                        .padding(AppSpacing.lg)
                }

                Divider()
                    .opacity(0.2)

                HStack(spacing: AppSpacing.sm) {
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
                .padding(AppSpacing.md)
                .background(Color.black.opacity(0.1))
            }
            .frame(maxWidth: 580)
            .frame(maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColors.surface2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppColors.border, lineWidth: 0.5)
            }
            .scaleEffect(0.985)
            .opacity(0.95)
            .transition(.scale(scale: 0.985).combined(with: .opacity))
            .animation(.easeOut(duration: 0.2), value: UUID())
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
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Account Name")
                    .font(AppTypography.captionLgSemibold)
                    .foregroundColor(.secondary)

                TextField("Enter name", text: .constant(""))
                    .padding(10)
                    .background(Color.black.opacity(0.25))
                    .cornerRadius(8)
            }
        }
    }
}
