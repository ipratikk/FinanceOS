import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

struct CategoryPickerView: View {
    let source: FinanceCore.Transaction
    let currentCategoryId: String?
    let currentMerchant: String?
    let previousPrediction: CategoryPrediction?
    var onCorrected: ((UUID, String) -> Void)?
    @Environment(\.transactionIntelligence) private var intelligence
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategoryId: String
    @State private var isSaving = false

    private let taxonomy = CategoryTaxonomy.current

    init(
        source: FinanceCore.Transaction,
        currentCategoryId: String?,
        currentMerchant: String?,
        previousPrediction: CategoryPrediction?,
        onCorrected: ((UUID, String) -> Void)? = nil
    ) {
        self.source = source
        self.currentCategoryId = currentCategoryId
        self.currentMerchant = currentMerchant
        self.previousPrediction = previousPrediction
        self.onCorrected = onCorrected
        _selectedCategoryId = State(initialValue: currentCategoryId ?? "uncategorized")
    }

    var body: some View {
        FDSSheet(
            title: "Change Category",
            subtitle: currentMerchant ?? source.description,
            onDismiss: { dismiss() },
            content: {
                VStack(spacing: AppSpacing.md) {
                    categoryList
                    saveButton
                }
            }
        )
    }

    private var categoryList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: AppSpacing.compact) {
                ForEach(taxonomy.categories, id: \.id) { category in
                    categoryRow(category)
                }
            }
        }
    }

    private func categoryRow(_ category: TaxonomyCategory) -> some View {
        let isSelected = selectedCategoryId == category.id
        return Button(action: { selectedCategoryId = category.id }, label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: CategorySymbol.symbol(for: category.id))
                    .foregroundStyle(CategorySymbol.color(for: category.id))
                    .frame(width: 24)

                FDSLabel(category.displayName)
                    .font(isSelected ? AppTypography.bodySmSemibold : AppTypography.bodySm)
                    .foregroundStyle(isSelected ? AppColors.Text.primary : AppColors.Text.secondary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(AppTypography.captionSmSemibold)
                        .foregroundStyle(AppColors.accentGold)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.compact)
            .background(isSelected ? AppColors.accentGold.opacity(0.08) : Color.clear)
            .cornerRadius(AppRadius.sm)
        })
        .buttonStyle(.plain)
    }

    private var saveButton: some View {
        Button(action: { Task { await save() } }, label: {
            HStack {
                if isSaving {
                    ProgressView().controlSize(.small)
                } else {
                    FDSLabel("Save")
                        .font(AppTypography.bodySmSemibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.accentGold)
            .foregroundStyle(.black)
            .cornerRadius(AppRadius.md)
        })
        .buttonStyle(.plain)
        .disabled(isSaving || selectedCategoryId == currentCategoryId)
    }

    private func save() async {
        isSaving = true
        if let service = intelligence {
            do {
                try await service.learn(
                    transaction: source,
                    correctedCategoryId: selectedCategoryId,
                    correctedMerchant: nil,
                    previousPrediction: previousPrediction
                )
            } catch {
                FinanceLogger.userInterface.logError("Category correction failed", caughtError: error, [:])
            }
        }
        onCorrected?(source.id, selectedCategoryId)
        isSaving = false
        dismiss()
    }
}
