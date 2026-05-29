import FinanceCore
import SwiftUI

/// Inline search bar with magnifying glass leading icon and clear button.
///
/// Renders a `surface2` rounded field. The clear button appears only when `text` is non-empty.
public struct FinanceSearchBar: View {
    @Binding var text: String
    let placeholder: String

    public init(_ placeholder: String = "Search", text: Binding<String>) {
        self.placeholder = placeholder
        _text = text
    }

    public var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textTertiary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .foregroundColor(AppColors.textPrimary)

            if !text.isEmpty {
                Button(action: { text = "" }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textTertiary)
                })
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface2)
        .cornerRadius(AppRadius.md)
    }
}

#Preview {
    @Previewable @State var text = ""

    return VStack {
        FinanceSearchBar("Search transactions", text: $text)
    }
    .padding(AppSpacing.lg)
    .background(AppColors.base)
}
