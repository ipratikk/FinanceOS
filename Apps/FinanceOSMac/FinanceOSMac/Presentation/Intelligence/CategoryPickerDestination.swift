import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

/// Category picker as a plain navigation destination.
/// Used inside TransactionDetailView's NavigationStack — no FDSSheet wrapper.
struct CategoryPickerDestination: View {
    let row: TransactionRow
    var onCorrected: ((UUID, String) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.transactionIntelligence) private var intelligence

    @State private var selectedCategoryId: String
    @State private var isSaving = false

    private let taxonomy = CategoryTaxonomy.current

    init(row: TransactionRow, onCorrected: ((UUID, String) -> Void)? = nil) {
        self.row = row
        self.onCorrected = onCorrected
        _selectedCategoryId = State(initialValue: row.categoryId ?? "uncategorized")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: AppSpacing.compact) {
                ForEach(taxonomy.categories, id: \.id) { category in
                    categoryRow(category)
                }
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.surface2)
        .navigationTitle("Change Category")
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { Task { await save() } }, label: {
                    if isSaving {
                        ProgressView().controlSize(.small)
                    } else {
                        FDSLabel("Save")
                            .font(AppTypography.bodySmSemibold)
                            .foregroundStyle(AppColors.accent)
                    }
                })
                .disabled(isSaving || selectedCategoryId == row.categoryId)
            }
        }
    }

    private func categoryRow(_ category: TaxonomyCategory) -> some View {
        let isSelected = selectedCategoryId == category.id
        return Button(action: { selectedCategoryId = category.id }, label: {
            HStack(spacing: AppSpacing.md) {
                FDSCategoryGlyph(category.id, icon: CategorySymbol.symbol(for: category.id), size: 32)
                FDSLabel(category.displayName)
                    .font(isSelected ? AppTypography.bodySmSemibold : AppTypography.bodySm)
                    .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(AppTypography.captionSmSemibold)
                        .foregroundStyle(AppColors.accent)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.compact)
            .background(isSelected ? AppColors.accent.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        })
        .buttonStyle(.plain)
    }

    private func save() async {
        guard let txn = row.sourceTransaction else { return }
        isSaving = true
        if let service = intelligence {
            try? await service.learn(
                transaction: txn,
                correctedCategoryId: selectedCategoryId,
                correctedMerchant: nil,
                previousPrediction: nil
            )
        }
        onCorrected?(txn.id, selectedCategoryId)
        isSaving = false
        dismiss()
    }
}
