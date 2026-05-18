import SwiftUI

/// Standard accessible icon button with guaranteed 44pt hit target.
/// Replaces all custom .frame(width: 22, height: 22) patterns.
public struct AccessibleIconButton: View {
    let icon: Image
    let label: String
    let hint: String?
    let action: () -> Void
    let style: Style

    public enum Style {
        case primary
        case secondary
        case destructive
    }

    public init(
        _ icon: Image,
        label: String,
        hint: String? = nil,
        style: Style = .secondary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.hint = hint
        self.action = action
        self.style = style
    }

    public var body: some View {
        Button(action: action) {
            icon
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .foregroundColor(foregroundColor)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(hint ?? "")
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .blue
        case .secondary: return .secondary
        case .destructive: return .red
        }
    }
}

// MARK: - Convenient Initializers

extension AccessibleIconButton {
    /// Close button (common pattern).
    public static func close(action: @escaping () -> Void) -> AccessibleIconButton {
        AccessibleIconButton(
            Image(systemName: "xmark"),
            label: "Close",
            hint: "Closes this dialog",
            style: .secondary,
            action: action
        )
    }

    /// Add/plus button.
    public static func add(label: String = "Add", action: @escaping () -> Void) -> AccessibleIconButton {
        AccessibleIconButton(
            Image(systemName: "plus"),
            label: label,
            hint: "Create new item",
            style: .primary,
            action: action
        )
    }

    /// Edit/pencil button.
    public static func edit(action: @escaping () -> Void) -> AccessibleIconButton {
        AccessibleIconButton(
            Image(systemName: "pencil"),
            label: "Edit",
            hint: "Edit this item",
            style: .secondary,
            action: action
        )
    }

    /// Delete/trash button.
    public static func delete(action: @escaping () -> Void) -> AccessibleIconButton {
        AccessibleIconButton(
            Image(systemName: "trash"),
            label: "Delete",
            hint: "Delete this item",
            style: .destructive,
            action: action
        )
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        AccessibleIconButton.add { }
        AccessibleIconButton.edit { }
        AccessibleIconButton.delete { }
        AccessibleIconButton.close { }
    }
    .padding()
}
