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
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                FDSText("Filters", style: .headingMedium)
                Spacer()
                Button(action: { dismiss() }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .headingSmall()
                        .foregroundColor(.gray)
                })
                .accessibilityLabel("Close filters")
            }
            .padding(AppSpacing.md)
            .background(AppColors.base)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        FDSText("Transaction Type", style: .captionLarge, color: .secondary)

                        Picker("Type", selection: $listState.typeFilter) {
                            Text("All").tag(TransactionType?.none)
                            Text("Debit").tag(TransactionType?.some(.debit))
                            Text("Credit").tag(TransactionType?.some(.credit))
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)

                    VStack(alignment: .leading, spacing: 12) {
                        FDSText("Date Range", style: .captionLarge, color: .secondary)

                        VStack(spacing: 8) {
                            HStack {
                                FDSText("From", style: .labelSmall)
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { listState.startDate ?? Date() },
                                        set: { listState.startDate = $0 }
                                    ),
                                    displayedComponents: [.date]
                                )
                                .labelsHidden()
                                if listState.startDate != nil {
                                    Button("Clear") {
                                        listState.startDate = nil
                                    }
                                    .labelSmall()
                                    .foregroundColor(.blue)
                                }
                            }
                            .padding(AppSpacing.xs)
                            .background(AppColors.surface2)
                            .cornerRadius(AppRadius.sm)

                            HStack {
                                FDSText("To", style: .labelSmall)
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { listState.endDate ?? Date() },
                                        set: { listState.endDate = $0 }
                                    ),
                                    displayedComponents: [.date]
                                )
                                .labelsHidden()
                                if listState.endDate != nil {
                                    Button("Clear") {
                                        listState.endDate = nil
                                    }
                                    .labelSmall()
                                    .foregroundColor(.blue)
                                }
                            }
                            .padding(AppSpacing.xs)
                            .background(AppColors.surface2)
                            .cornerRadius(AppRadius.sm)
                        }
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)

                    if let error = dateRangeError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .labelSmall()
                                .foregroundColor(.red)
                            FDSText(error, style: .labelSmall, color: .warning)
                        }
                        .padding(AppSpacing.xs)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(AppSpacing.md)
            }

            Divider()

            HStack(spacing: 12) {
                Button(action: { listState.reset() }, label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Reset")
                    }
                    .bodyLarge()
                    .frame(maxWidth: .infinity)
                })
                .foregroundColor(.blue)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)

                Button(action: { dismiss() }, label: {
                    FDSText("Done", style: .monoAmount)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                })
                .padding(AppSpacing.sm)
                .background(AppColors.accent)
                .cornerRadius(AppRadius.md)
            }
            .padding(AppSpacing.md)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.base)
    }
}

#Preview {
    TransactionFilterView(listState: TransactionListState())
}
