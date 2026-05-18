import FinanceCore
import FinanceUI
import SwiftUI

struct TransactionFilterView: View {
    @Bindable var listState: TransactionListState
    @Environment(\.dismiss) var dismiss

    var dateRangeError: String? {
        guard let start = listState.startDate, let end = listState.endDate else { return nil }
        return end < start ? "End date must be after start date" : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    typeSection
                    dateSection
                    if let error = dateRangeError {
                        errorBanner(error)
                    }
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
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(AppColors.accent)
                .symbolRenderingMode(.hierarchical)
            Text("Filters")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
    }

    private var typeSection: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("TRANSACTION TYPE")
                    .font(.system(size: 10, weight: .semibold))
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
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)

                dateRow(label: "From", date: Binding(
                    get: { listState.startDate ?? Date() },
                    set: { listState.startDate = $0 }
                ), isSet: listState.startDate != nil) {
                    listState.startDate = nil
                }

                dateRow(label: "To", date: Binding(
                    get: { listState.endDate ?? Date() },
                    set: { listState.endDate = $0 }
                ), isSet: listState.endDate != nil) {
                    listState.endDate = nil
                }
            }
        }
    }

    private func dateRow(
        label: String,
        date: Binding<Date>,
        isSet: Bool,
        onClear: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)

            Spacer()

            DatePicker("", selection: date, displayedComponents: [.date])
                .labelsHidden()
                .controlSize(.small)

            if isSet {
                Button("Clear", action: onClear)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.accent)
                    .buttonStyle(.plain)
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: AppSpacing.compact) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
            Text(message)
                .font(.system(size: 12, weight: .medium))
            Spacer()
        }
        .foregroundStyle(AppColors.debit)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.compact)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.debit.opacity(0.12))
        }
    }

    private var footer: some View {
        HStack(spacing: AppSpacing.compact) {
            FDSLiquidButton("Reset", symbol: "arrow.clockwise", variant: .subtle) {
                listState.reset()
            }
            Spacer()
            FDSLiquidButton("Done", variant: .primary) { dismiss() }
        }
        .padding(AppSpacing.md)
    }
}
