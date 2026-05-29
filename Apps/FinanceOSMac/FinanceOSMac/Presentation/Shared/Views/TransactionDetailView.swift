import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

struct TransactionDetailView: View {
    let row: TransactionRow
    var onCorrected: ((UUID, String) -> Void)?
    @Environment(\.dismiss) var dismiss
    @Environment(\.transactionIntelligence) private var intelligence
    @State private var showCategoryPicker = false
    @State private var viewModel: TransactionDetailViewModel

    init(row: TransactionRow, onCorrected: ((UUID, String) -> Void)? = nil) {
        self.row = row
        self.onCorrected = onCorrected
        _viewModel = State(initialValue: TransactionDetailViewModel(row: row))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    heroCard
                    detailSections
                }
                .padding(AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColors.surface2)
            .navigationTitle(row.displayTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $showCategoryPicker) {
                categoryPickerDestination
            }
        }
        .frame(width: 560)
        .frame(minHeight: 560, maxHeight: 720)
    }
}

// MARK: - Hero Card

private extension TransactionDetailView {
    var heroCard: some View {
        FDSCard(cornerRadius: 16, padded: false) {
            VStack(spacing: 0) {
                // Identity strip
                HStack(spacing: AppSpacing.md) {
                    FDSMerchantAvatar(
                        name: row.displayTitle,
                        symbol: viewModel.categorySymbol,
                        imageName: nil,
                        size: FDSAvatarSize.hero.value
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        FDSLabel(row.displayTitle)
                            .font(AppTypography.headingMd)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(2)
                        if let catId = viewModel.categoryId {
                            categoryBadge(catId)
                        }
                    }
                    Spacer()
                }
                .padding(AppSpacing.lg)

                Divider().opacity(0.1)

                // Amount block — separate row
                VStack(spacing: AppSpacing.tight) {
                    FDSLabel(row.transactionType == .debit ? "DEBITED" : "CREDITED")
                        .font(AppTypography.captionSmSemibold)
                        .tracking(0.6)
                        .foregroundStyle(.tertiary)

                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.compact) {
                        FDSAmount(row.amountText, type: row.transactionType == .debit ? .debit : .credit, size: .hero)
                        Image(systemName: row
                            .transactionType == .debit ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(AppTypography.headingMd)
                            .foregroundStyle(row.transactionType == .debit ? AppColors.debit : AppColors.credit)
                    }

                    if let balance = row.runningBalance {
                        FDSLabel("Balance after: \(balance)")
                            .font(AppTypography.captionLg.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.xl)
            }
        }
    }
}

// MARK: - Detail Sections

private extension TransactionDetailView {
    var detailSections: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            dateTimeSection
            sourceSection
            categorySection
            if viewModel.showNarration {
                narrationSection
            }
        }
    }

    var dateTimeSection: some View {
        sectionCard(header: "Date & Time") {
            infoRow(icon: "calendar", label: viewModel.postedDateText)
            Divider().opacity(0.1)
            infoRow(icon: "clock", label: viewModel.postedTimeText)
        }
    }

    var sourceSection: some View {
        sectionCard(header: "Source") {
            infoRow(icon: "building.columns", label: row.subtitle)
        }
    }

    var categorySection: some View {
        sectionCard(header: "Category") {
            HStack(spacing: AppSpacing.md) {
                FDSCategoryGlyph(
                    viewModel.categoryId ?? "other",
                    icon: viewModel.categorySymbol,
                    size: 36
                )
                VStack(alignment: .leading, spacing: 3) {
                    FDSLabel(viewModel.categoryDisplayName)
                        .font(AppTypography.bodySmMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    if viewModel.isUserCorrected {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(AppTypography.captionSm)
                                .foregroundStyle(AppColors.accent)
                            FDSLabel("You corrected this")
                                .font(AppTypography.captionLg)
                                .foregroundStyle(AppColors.accent)
                        }
                    } else {
                        FDSLabel("ML categorized")
                            .font(AppTypography.captionLg)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                if intelligence != nil, row.sourceTransaction != nil {
                    Button(action: { showCategoryPicker = true }, label: {
                        HStack(spacing: 4) {
                            FDSLabel("Change")
                                .font(AppTypography.captionLgSemibold)
                                .foregroundStyle(AppColors.accent)
                            Image(systemName: "chevron.right")
                                .font(AppTypography.captionSm)
                                .foregroundStyle(AppColors.accent.opacity(0.7))
                        }
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.tight)
                        .background(AppColors.accent.opacity(0.1))
                        .clipShape(Capsule())
                    })
                    .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.md)
        }
    }

    var narrationSection: some View {
        sectionCard(header: "Bank Narration") {
            FDSLabel(row.title)
                .font(AppTypography.captionLg.monospaced())
                .foregroundStyle(AppColors.textSecondary)
                .padding(AppSpacing.md)
        }
    }

    /// Category picker as NavigationStack destination — no FDSSheet wrapper
    var categoryPickerDestination: some View {
        CategoryPickerDestination(
            row: row,
            onCorrected: { id, catId in
                viewModel.applyCorrection(transactionId: id, newCategoryId: catId)
                onCorrected?(id, catId)
                showCategoryPicker = false
            }
        )
    }
}

// MARK: - Helpers

private extension TransactionDetailView {
    func sectionCard(header: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            FDSLabel(header.uppercased())
                .font(AppTypography.captionSmSemibold)
                .tracking(0.5)
                .foregroundStyle(.tertiary)
            FDSCard(cornerRadius: 12, padded: false) {
                content()
            }
        }
    }

    func infoRow(icon: String, label: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(AppTypography.captionLgSemibold)
                .foregroundStyle(.tertiary)
                .frame(width: 20)
            FDSLabel(label)
                .font(AppTypography.bodySmMedium)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
        }
        .padding(AppSpacing.md)
    }

    func categoryBadge(_ categoryId: String) -> some View {
        let label = viewModel.categoryDisplayName
        let color = viewModel.categoryColor
        return FDSLabel(label.uppercased())
            .font(AppTypography.captionSmSemibold)
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}
