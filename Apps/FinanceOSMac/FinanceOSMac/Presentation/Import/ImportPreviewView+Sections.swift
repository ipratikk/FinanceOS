import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

extension ImportPreviewView {
    var targetSelectionMenu: some View {
        Menu {
            if viewModel.selectedTarget != nil {
                Button(action: {
                    viewModel.selectedTarget = nil
                }) {
                    Text("Clear Selection")
                }
                Divider()
            }

            let accounts = viewModel.ledgers.filter { $0.kind == .bankAccount }
            if !accounts.isEmpty {
                Menu("Accounts") {
                    ForEach(accounts) { account in
                        Button(action: {
                            viewModel.selectedTarget = .ledger(account.id)
                        }) {
                            if case let .ledger(id) = viewModel.selectedTarget, id == account.id {
                                Label(account.displayName, systemImage: "checkmark")
                            } else {
                                Text(account.displayName)
                            }
                        }
                    }
                }
            }
            Button(action: { initializeCreateSheet(isCard: false) }) {
                Text("Create New Account...")
            }

            let cards = viewModel.ledgers.filter { $0.kind == .creditCard }
            if !cards.isEmpty {
                Menu("Cards") {
                    ForEach(cards) { card in
                        Button(action: {
                            viewModel.selectedTarget = .ledger(card.id)
                        }) {
                            if case let .ledger(id) = viewModel.selectedTarget, id == card.id {
                                Label(card.displayName, systemImage: "checkmark")
                            } else {
                                Text(card.displayName)
                            }
                        }
                    }
                }
            }
            Button(action: { initializeCreateSheet(isCard: true) }) {
                Text("Create New Card...")
            }
        } label: {
            let displayText: String = {
                if let target = viewModel.selectedTarget {
                    if case let .ledger(id) = target {
                        return viewModel.ledgers.first { $0.id == id }?.displayName ?? "Ledger"
                    }
                }
                return "Select Account or Card..."
            }()

            HStack(spacing: 6) {
                Text(displayText)
                    .font(AppTypography.labelMedium)
                    .foregroundColor(DesignTokens.Text.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignTokens.Text.secondary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(DesignTokens.Background.surface)
            .cornerRadius(AppRadius.sm)
        }
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

    var confirmBar: some View {
        let allTransactions = viewModel.parsedStatements.flatMap(\.transactions)
        let newCount = allTransactions.count - viewModel.duplicateTransactionIndices.count
        let dupCount = viewModel.duplicateTransactionIndices.count

        return HStack(spacing: AppSpacing.md) {
            Text("\(newCount) new · \(dupCount) duplicate\(dupCount == 1 ? "" : "s")")
                .font(AppTypography.labelSmall)
                .foregroundColor(DesignTokens.Text.secondary)

            Spacer()

            Button(action: { viewModel.backToUpload() }) {
                Text("Cancel")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(DesignTokens.Text.primary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .stroke(DesignTokens.Text.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button(action: { viewModel.importTransactions() }) {
                Text("Import \(newCount) transaction\(newCount == 1 ? "" : "s")")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(newCount > 0 ? AppColors.accent : Color.gray)
                    .cornerRadius(AppRadius.sm)
            }
            .buttonStyle(.plain)
            .disabled(newCount == 0 || viewModel.selectedTarget == nil)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(DesignTokens.Background.surfaceGlass)
        .overlay(
            Divider(),
            alignment: .top
        )
    }
}
