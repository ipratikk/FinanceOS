import FinanceCore
import FinanceUI
import SwiftUI

struct TransactionFilterView: View {
    @Bindable var listState: TransactionListState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    typeSection
                    dateSection
                }
                .padding(AppSpacing.xl)
            }

            Divider().opacity(0.3)
            footer
        }
        .frame(width: 480, height: 560)
        .background(AppColors.base)
    }

    private var header: some View {
        HStack(spacing: AppSpacing.compact) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(AppTypography.headingMdRegular)
                .foregroundStyle(AppColors.accent)
                .symbolRenderingMode(.hierarchical)
            FDSLabel("Filters")
                .font(AppTypography.bodyMd)
                .foregroundStyle(AppColors.Text.secondary)
            Spacer()
            Button(action: { dismiss() }, label: {
                Image(systemName: "xmark")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.Text.tertiary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(.ultraThinMaterial))
            })
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
    }

    private var typeSection: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                FDSLabel("TRANSACTION TYPE")
                    .font(AppTypography.labelSemibold)
                    .tracking(0.5)
                    .foregroundStyle(.tertiary)

                Picker("Type", selection: $listState.typeFilter) {
                    FDSLabel("All").tag(TransactionType?.none)
                    FDSLabel("Debit").tag(TransactionType?.some(.debit))
                    FDSLabel("Credit").tag(TransactionType?.some(.credit))
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
    }

    private var dateSection: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                FDSLabel("DATE RANGE")
                    .font(AppTypography.labelSemibold)
                    .tracking(0.5)
                    .foregroundStyle(.tertiary)

                ForEach(DateRangeFilter.standardPresets, id: \.label) { preset in
                    presetRow(preset)
                }

                Divider().opacity(0.3)

                ForEach(listState.availableFinancialYears, id: \.self) { year in
                    presetRow(.financialYear(year))
                }
            }
        }
    }

    private func presetRow(_ preset: DateRangeFilter) -> some View {
        Button {
            listState.dateRangeFilter = listState.dateRangeFilter == preset ? nil : preset
        } label: {
            HStack {
                FDSLabel(preset.label)
                    .font(AppTypography.bodySm)
                    .foregroundStyle(.primary)
                Spacer()
                if listState.dateRangeFilter == preset {
                    Image(systemName: "checkmark")
                        .font(AppTypography.captionLgSemibold)
                        .foregroundStyle(AppColors.accent)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack(spacing: AppSpacing.compact) {
            FDSLiquidButton("Reset", symbol: "arrow.clockwise", variant: .ghost) {
                listState.reset()
            }
            Spacer()
            FDSLiquidButton("Done", variant: .primary) { dismiss() }
        }
        .padding(AppSpacing.md)
    }
}
