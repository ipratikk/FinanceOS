import FinanceCore
import SwiftUI

struct TransactionFilterView: View {
    @Bindable var listState: TransactionListState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Filters")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(action: { dismiss() }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                })
            }
            .padding(AppSpacing.md)
            .background(AppColors.base)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transaction Type")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)

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
                        Text("Date Range")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            HStack {
                                Text("From")
                                    .font(.system(size: 12, weight: .regular))
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
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.blue)
                                }
                            }
                            .padding(AppSpacing.xs)
                            .background(AppColors.surface2)
                            .cornerRadius(AppRadius.sm)

                            HStack {
                                Text("To")
                                    .font(.system(size: 12, weight: .regular))
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
                                    .font(.system(size: 11, weight: .medium))
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
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                })
                .foregroundColor(.blue)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)

                Button(action: { dismiss() }, label: {
                    Text("Done")
                        .font(.system(size: 14, weight: .semibold))
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
