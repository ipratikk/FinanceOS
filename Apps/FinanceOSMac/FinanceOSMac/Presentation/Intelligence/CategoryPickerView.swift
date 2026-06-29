import FinanceCore
import FinanceUI
import SwiftUI

struct CategoryPickerView: View {
    let source: FinanceCore.Transaction
    let currentMerchant: String?
    let graphQLClient: ApolloGraphQLClient
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CategoryCorrectionViewModel

    private let taxonomy = CategoryTaxonomy.current

    init(
        source: FinanceCore.Transaction,
        currentCategoryId: String?,
        currentMerchant: String?,
        graphQLClient: ApolloGraphQLClient,
        onCorrected: ((UUID, String) -> Void)? = nil
    ) {
        self.source = source
        self.currentMerchant = currentMerchant
        self.graphQLClient = graphQLClient
        _viewModel = State(initialValue: CategoryCorrectionViewModel(
            transaction: source,
            currentCategoryId: currentCategoryId,
            graphQLClient: graphQLClient,
            onCorrected: onCorrected
        ))
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
        let isSelected = viewModel.selectedCategoryId == category.id
        return Button(action: { viewModel.selectedCategoryId = category.id }, label: {
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
        Button(
            action: { Task { await viewModel.save(onDismiss: { dismiss() }) } },
            label: {
                HStack {
                    if viewModel.isSaving {
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
            }
        )
        .buttonStyle(.plain)
        .disabled(viewModel.isSaveDisabled)
    }
}
