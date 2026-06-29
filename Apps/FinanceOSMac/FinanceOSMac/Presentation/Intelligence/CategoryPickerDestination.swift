import FinanceCore
import FinanceUI
import SwiftUI

/// Category picker as a plain navigation destination.
/// Used inside TransactionDetailView's NavigationStack — no FDSSheet wrapper.
struct CategoryPickerDestination: View {
    let row: TransactionRow
    let graphQLClient: ApolloGraphQLClient
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CategoryCorrectionViewModel

    private let taxonomy = CategoryTaxonomy.current

    init(row: TransactionRow, graphQLClient: ApolloGraphQLClient, onCorrected: ((UUID, String) -> Void)? = nil) {
        self.row = row
        self.graphQLClient = graphQLClient
        _viewModel = State(initialValue: CategoryCorrectionViewModel(
            row: row,
            graphQLClient: graphQLClient,
            onCorrected: onCorrected
        ))
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
                Button(action: {
                    Task { await viewModel.save(onDismiss: { dismiss() }) }
                }, label: {
                    if viewModel.isSaving {
                        ProgressView().controlSize(.small)
                    } else {
                        FDSLabel("Save")
                            .font(AppTypography.bodySmSemibold)
                            .foregroundStyle(AppColors.accent)
                    }
                })
                .disabled(viewModel.isSaveDisabled)
            }
        }
    }

    private func categoryRow(_ category: TaxonomyCategory) -> some View {
        let isSelected = viewModel.selectedCategoryId == category.id
        return Button(action: { viewModel.selectedCategoryId = category.id }, label: {
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
}
