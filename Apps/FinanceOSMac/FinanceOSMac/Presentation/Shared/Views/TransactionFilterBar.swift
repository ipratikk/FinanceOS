import FinanceCore
import FinanceUI
import SwiftUI

struct TransactionFilterBar: View {
    @Bindable var listState: TransactionListState
    @Binding var showDatePopover: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.compact) {
                typeChip(label: "Debit", type: .debit)
                typeChip(label: "Credit", type: .credit)

                Divider()
                    .frame(height: 16)
                    .opacity(0.3)

                dateChip

                if listState.isFilterActive {
                    Button(action: { listState.reset() }, label: {
                        HStack(spacing: 3) {
                            Image(systemName: "xmark.circle.fill")
                                .font(AppTypography.label)
                            FDSLabel("Clear")
                                .font(AppTypography.captionLgMedium)
                        }
                        .foregroundStyle(AppColors.accentGold)
                    })
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.compact)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: listState.isFilterActive)
    }

    private func typeChip(label: String, type: TransactionType) -> some View {
        let active = listState.typeFilter == type
        let color = type == .debit ? AppColors.danger : AppColors.success
        return Button {
            listState.typeFilter = active ? nil : type
        } label: {
            FDSLabel(label)
                .font(active ? AppTypography.captionLgSemibold : AppTypography.captionLg)
                .foregroundStyle(active ? color : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 5)
                .background {
                    Capsule(style: .continuous)
                        .fill(active ? color.opacity(0.1) : AppColors.clear)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(
                                    active ? color.opacity(0.2) : AppColors.accentSlate.opacity(0.1),
                                    lineWidth: 0.5
                                )
                        )
                }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: active)
    }

    private var dateChip: some View {
        let active = listState.dateRangeFilter != nil
        return Button {
            showDatePopover = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(AppTypography.captionSmMedium)
                FDSLabel(listState.dateRangeFilter?.label ?? "Date")
                    .font(active ? AppTypography.captionLgSemibold : AppTypography.captionLg)
                if !active {
                    Image(systemName: "chevron.down")
                        .font(AppTypography.iconSm)
                }
            }
            .foregroundStyle(active ? AppColors.accentGold : AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 5)
            .background {
                Capsule(style: .continuous)
                    .fill(active ? AppColors.accentGold.opacity(0.1) : AppColors.clear)
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(
                                active ? AppColors.accentGold.opacity(0.2) : AppColors.accentSlate.opacity(0.1),
                                lineWidth: 0.5
                            )
                    )
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showDatePopover, arrowEdge: .bottom) {
            DateFilterPopover(listState: listState, isPresented: $showDatePopover)
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: active)
    }
}
