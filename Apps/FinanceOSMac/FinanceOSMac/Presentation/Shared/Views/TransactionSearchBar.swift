import FinanceCore
import FinanceUI
import SwiftUI

struct TransactionSearchBar: View {
    @Binding var searchQuery: String

    var body: some View {
        HStack(spacing: AppSpacing.compact) {
            HStack(spacing: AppSpacing.compact) {
                Image(systemName: "magnifyingglass")
                    .font(AppTypography.captionLgSemibold)
                    .foregroundStyle(.tertiary)

                FDSTextInput("Search transactions", text: $searchQuery, style: .bodyMedium)
                    .textFieldStyle(.plain)

                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(AppTypography.captionLg)
                            .foregroundStyle(.tertiary)
                    })
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.compact)
            .padding(.vertical, 6)
            .background { Capsule(style: .continuous).fill(.ultraThinMaterial) }
            .overlay { Capsule(style: .continuous).strokeBorder(AppColors.accentSlate.opacity(0.08), lineWidth: 0.5) }
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.compact)
    }
}
