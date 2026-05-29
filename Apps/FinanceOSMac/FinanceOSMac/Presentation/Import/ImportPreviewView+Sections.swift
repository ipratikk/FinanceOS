import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

extension ImportPreviewView {
    var targetSelectionMenu: some View {
        let selected: (name: String, icon: String)? = {
            guard let target = viewModel.selectedTarget,
                  case let .ledger(id) = target,
                  let ledger = viewModel.ledgers.first(where: { $0.id == id })
            else { return nil }
            let icon = ledger.kind == .creditCard ? "creditcard" : "building.columns"
            return (ledger.displayName, icon)
        }()

        return FDSLiquidButton(
            selected?.name ?? "Select destination...",
            leadingIcon: selected?.icon,
            trailingIcon: "chevron.up.chevron.down",
            variant: .primary,
            action: { isTargetMenuOpen.toggle() }
        )
        .popover(isPresented: $isTargetMenuOpen, arrowEdge: .top) {
            targetMenuPopover
        }
    }

    private var targetMenuPopover: some View {
        FDSGlassSurface(elevation: .floating, cornerRadius: AppRadius.lg, padding: 0) {
            VStack(spacing: 0) {
                accountMenuRows
                Divider()
                    .padding(AppSpacing.sm)
                cardMenuRows
                if viewModel.selectedTarget != nil {
                    Divider().padding(.horizontal, AppSpacing.sm)
                    clearMenuRow
                }
            }
            .frame(minWidth: 260)
            .padding(.vertical, AppSpacing.compact)
        }
    }

    private var accountMenuRows: some View {
        let accounts = viewModel.ledgers.filter { $0.kind == .bankAccount }
        return VStack(spacing: 0) {
            ForEach(accounts) { account in
                let isSelected: Bool = {
                    if case let .ledger(id) = viewModel.selectedTarget { return id == account.id }
                    return false
                }()
                ledgerMenuRow(title: account.displayName, icon: "building.columns", isSelected: isSelected) {
                    viewModel.selectedTarget = .ledger(account.id)
                    isTargetMenuOpen = false
                }
            }
            menuActionRow(title: "New Account...", icon: "plus.circle") {
                isTargetMenuOpen = false
                initializeCreateSheet(isCard: false)
            }
        }
    }

    private var cardMenuRows: some View {
        let cards = viewModel.ledgers.filter { $0.kind == .creditCard }
        return VStack(spacing: 0) {
            ForEach(cards) { card in
                let isSelected: Bool = {
                    if case let .ledger(id) = viewModel.selectedTarget { return id == card.id }
                    return false
                }()
                ledgerMenuRow(title: card.displayName, icon: "creditcard", isSelected: isSelected) {
                    viewModel.selectedTarget = .ledger(card.id)
                    isTargetMenuOpen = false
                }
            }
            menuActionRow(title: "New Card...", icon: "plus.circle") {
                isTargetMenuOpen = false
                initializeCreateSheet(isCard: true)
            }
        }
    }

    private var clearMenuRow: some View {
        Button(action: { viewModel.selectedTarget = nil; isTargetMenuOpen = false }, label: {
            HStack {
                Spacer()
                FDSLabel("Clear Selection")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.Text.tertiary)
                Spacer()
            }
            .padding(.vertical, AppSpacing.compact)
            .padding(.horizontal, AppSpacing.md)
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }

    private func ledgerMenuRow(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action, label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(AppTypography.captionLg)
                    .foregroundStyle(isSelected ? AppColors.accent : AppColors.Text.tertiary)
                    .frame(width: 16)
                FDSLabel(title)
                    .font(AppTypography.bodyMd)
                    .foregroundStyle(isSelected ? AppColors.accent : AppColors.Text.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppTypography.captionLg)
                        .foregroundStyle(AppColors.accent)
                }
            }
            .padding(.vertical, AppSpacing.compact)
            .padding(.horizontal, AppSpacing.md)
            .background(isSelected ? AppColors.accent.opacity(0.08) : AppColors.clear)
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }

    private func menuActionRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(AppTypography.captionLg)
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 16)
                FDSLabel(title)
                    .font(AppTypography.bodyMd)
                    .foregroundStyle(AppColors.accent)
                Spacer()
            }
            .padding(.vertical, AppSpacing.compact)
            .padding(.horizontal, AppSpacing.md)
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }

    func initializeCreateSheet(isCard: Bool) {
        guard let statement = viewModel.importSession.parsedStatements.first else {
            var state = TargetCreationState()
            state.isCard = isCard
            viewModel.importSession.targetBeingCreated = state
            return
        }

        var state = TargetCreationState()
        state.isCard = isCard
        state.initializeFromStatement(statement)

        let detected = statement.bankName.isEmpty ? "Unknown" : statement.bankName
        let matchingBankCase = Banks.allCases.first { bankCase in
            ImportFormatting.fuzzyMatch(bankCase.displayName, detected)
        }
        state.selectedBank = matchingBankCase

        viewModel.importSession.targetBeingCreated = state
    }

    @ViewBuilder var confirmBar: some View {
        let allTransactions = viewModel.parsedStatements.flatMap(\.transactions)
        let newCount = allTransactions.count - viewModel.duplicateTransactionIndices.count
        let dupCount = viewModel.alreadyInDBIndices.count

        if newCount == 0, dupCount > 0 {
            allCaughtUpBar(dupCount: dupCount)
        } else {
            normalConfirmBar(newCount: newCount, dupCount: dupCount)
        }
    }

    private func allCaughtUpBar(dupCount: Int) -> some View {
        FDSCard(padded: false) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.success)

                FDSLabel("All \(dupCount) transaction\(dupCount == 1 ? "" : "s") already imported")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.Text.secondary)

                Spacer()

                FDSLiquidButton("Import Another", variant: .primary, action: viewModel.backToUpload)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
    }

    private func normalConfirmBar(newCount: Int, dupCount: Int) -> some View {
        FDSCard(padded: false) {
            HStack(spacing: AppSpacing.md) {
                FDSLabel("\(newCount) new · \(dupCount) duplicate\(dupCount == 1 ? "" : "s")")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.Text.secondary)

                Spacer()

                FDSLiquidButton("Cancel", variant: .ghost, action: viewModel.backToUpload)

                FDSLiquidButton(
                    "Import \(newCount) transaction\(newCount == 1 ? "" : "s")",
                    variant: .primary,
                    isEnabled: newCount > 0 && viewModel.selectedTarget != nil,
                    action: viewModel.importTransactions
                )
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
    }
}
