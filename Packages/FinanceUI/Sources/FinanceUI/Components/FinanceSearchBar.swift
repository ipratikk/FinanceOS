import SwiftUI

public struct FinanceSearchBar: View {
    @Binding var text: String
    let placeholder: String

    public init(_ placeholder: String = "Search", text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textTertiary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .foregroundColor(AppColors.textPrimary)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface2)
        .cornerRadius(AppRadius.md)
    }
}

#Preview {
    @State var text = ""

    return VStack {
        FinanceSearchBar("Search transactions", text: $text)
    }
    .padding(AppSpacing.lg)
    .background(AppColors.base)
}
