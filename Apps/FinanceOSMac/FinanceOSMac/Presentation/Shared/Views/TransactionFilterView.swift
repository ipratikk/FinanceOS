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
                .font(AppTypography.headlineMdRegular)
                .foregroundStyle(AppColors.accent)
                .symbolRenderingMode(.hierarchical)
            Text("Filters").bodyMedium()
            Spacer()
            Button(action: { dismiss() }, label: {
                Image(systemName: "xmark")
                    .labelSmall()
                    .foregroundStyle(.secondary)
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
                Text("TRANSACTION TYPE")
                    .font(AppTypography.labelSemibold)
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)

                Picker("Type", selection: $listState.typeFilter) {
                    Text("All").tag(TransactionType?.none)
                    Text("Debit").tag(TransactionType?.some(.debit))
                    Text("Credit").tag(TransactionType?.some(.credit))
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
    }

    private var dateSection: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("DATE RANGE")
                    .font(AppTypography.labelSemibold)
                    .tracking(0.6)
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
                Text(preset.label)
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
