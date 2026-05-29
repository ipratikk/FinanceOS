import FinanceCore
import FinanceUI
import SwiftUI

struct DateFilterPopover: View {
    @Bindable var listState: TransactionListState
    @Binding var isPresented: Bool

    @State private var customFrom: Date = Date()
    @State private var customTo: Date = Date()

    private var isCustom: Bool {
        if case .custom = listState.dateRangeFilter { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FDSLabel("DATE RANGE")
                .font(AppTypography.labelSemibold)
                .tracking(0.5)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.compact)

            ForEach(DateRangeFilter.standardPresets, id: \.label) { preset in
                presetRow(preset)
            }

            if !listState.availableFinancialYears.isEmpty {
                Divider().opacity(0.3).padding(.vertical, 4)
                ForEach(listState.availableFinancialYears, id: \.self) { year in
                    presetRow(.financialYear(year))
                }
            }

            Divider().opacity(0.3).padding(.vertical, 4)

            customRow

            if isCustom {
                customDatePickers
            }

            Spacer(minLength: 0)
        }
        .frame(width: 220)
        .padding(.bottom, AppSpacing.md)
        .background(AppColors.base)
        .onAppear {
            if case let .custom(from, endDate) = listState.dateRangeFilter {
                if let from { customFrom = from }
                if let endDate { customTo = endDate }
            }
        }
    }

    private func presetRow(_ preset: DateRangeFilter) -> some View {
        let active = listState.dateRangeFilter == preset
        return Button {
            listState.dateRangeFilter = active ? nil : preset
            if !isCustom { isPresented = false }
        } label: {
            HStack {
                FDSLabel(preset.label)
                    .font(active ? AppTypography.bodySmSemibold : AppTypography.bodySm)
                    .foregroundStyle(active ? AppColors.accentGold : AppColors.textPrimary)
                Spacer()
                if active {
                    Image(systemName: "checkmark")
                        .font(AppTypography.captionSmSemibold)
                        .foregroundStyle(AppColors.accentGold)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var customRow: some View {
        let active = isCustom
        return Button {
            if active {
                listState.dateRangeFilter = nil
            } else {
                listState.dateRangeFilter = .custom(from: nil, endDate: nil)
            }
        } label: {
            HStack {
                FDSLabel("Custom")
                    .font(active ? AppTypography.bodySmSemibold : AppTypography.bodySm)
                    .foregroundStyle(active ? AppColors.accent : AppColors.textPrimary)
                Spacer()
                Image(systemName: active ? "checkmark" : "chevron.right")
                    .font(AppTypography.captionSmSemibold)
                    .foregroundStyle(active ? AppColors.accent : AppColors.textSecondary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var customDatePickers: some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            customDateRow(label: "From", date: Binding(
                get: { customFrom },
                set: { customFrom = $0; listState.dateRangeFilter = .custom(from: $0, endDate: customTo) }
            ))
            customDateRow(label: "To", date: Binding(
                get: { customTo },
                set: { customTo = $0; listState.dateRangeFilter = .custom(from: customFrom, endDate: $0) }
            ))
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.compact)
        .background(AppColors.accentGold.opacity(0.05))
    }

    private func customDateRow(label: String, date: Binding<Date>) -> some View {
        HStack {
            FDSLabel(label)
                .font(AppTypography.captionLgMedium)
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .leading)
            DatePicker("", selection: date, displayedComponents: [.date])
                .labelsHidden()
                .controlSize(.small)
        }
    }
}
