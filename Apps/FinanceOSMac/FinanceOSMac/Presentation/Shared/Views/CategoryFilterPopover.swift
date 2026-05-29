import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

struct CategoryFilterPopover: View {
    @Binding var selectedCategoryId: String?
    private let taxonomy = CategoryTaxonomy.current

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FDSLabel("FILTER BY CATEGORY")
                .font(AppTypography.captionSmSemibold)
                .tracking(0.5)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.compact)

            Divider().opacity(0.1)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    row(id: nil, name: "All Categories", icon: "tray.2")
                    Divider().opacity(0.08)
                    ForEach(taxonomy.categories, id: \.id) { cat in
                        row(id: cat.id, name: cat.displayName, icon: CategorySymbol.symbol(for: cat.id))
                        if cat.id != taxonomy.categories.last?.id {
                            Divider().opacity(0.08).padding(.leading, 44)
                        }
                    }
                }
            }
        }
        .frame(width: 220, height: 360)
        .background(AppColors.surface2)
    }

    private func row(id: String?, name: String, icon: String) -> some View {
        let isSelected = selectedCategoryId == id
        return Button(action: { selectedCategoryId = id }, label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(AppTypography.captionLg)
                    .foregroundStyle(id == nil ? Color.secondary : CategorySymbol.color(for: id))
                    .frame(width: 20)
                FDSLabel(name)
                    .font(isSelected ? AppTypography.captionLgSemibold : AppTypography.captionLg)
                    .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(AppTypography.captionSm)
                        .foregroundStyle(AppColors.accentPurple)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.compact)
            .background(isSelected ? AppColors.accentPurple.opacity(0.08) : Color.clear)
        })
        .buttonStyle(.plain)
    }
}
