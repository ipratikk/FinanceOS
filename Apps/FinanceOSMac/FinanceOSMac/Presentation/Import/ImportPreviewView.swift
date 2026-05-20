import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct ImportPreviewView: View {
    let viewModel: ImportViewModel

    @State private var sheetCreationItem: TargetCreationState?
    @State private var importedExpanded = false
    @State private var duplicatesExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .caption()
                        .foregroundColor(.red)
                    Spacer()
                    Button(action: { viewModel.errorMessage = nil }, label: {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.debit)
                    })
                }
                .padding(AppSpacing.sm)
                .background(AppColors.debit.opacity(0.1))
                .cornerRadius(AppRadius.sm)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
            }

            // Header with Review heading and Import to dropdown
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Review parsed transactions")
                        .font(AppTypography.headingMd)
                        .foregroundColor(DesignTokens.Text.primary)

                    if !viewModel.parsedStatements.isEmpty {
                        let newCount = viewModel.parsedStatements.count - viewModel.duplicateTransactionIndices.count
                        let dupCount = viewModel.duplicateTransactionIndices.count
                        let fileName = viewModel.fileURLs.first?.lastPathComponent ?? "File"
                        let total = viewModel.parsedStatements.count
                        Text("\(fileName) · \(total) rows · \(newCount) new, \(dupCount) duplicate")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(DesignTokens.Text.tertiary)
                    }
                }

                Spacer()

                targetSelectionMenu
            }
            .padding(AppSpacing.lg)
            .background(DesignTokens.Background.surfaceGlass)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                if !importedTransactions.isEmpty {
                    ImportTransactionSection(
                        title: "New Transactions",
                        badgeCount: importedTransactions.count,
                        transactions: importedTransactions,
                        duplicateIndices: [],
                        isExpanded: $importedExpanded
                    )
                }

                if !duplicateTransactions.isEmpty {
                    ImportTransactionSection(
                        title: "Already imported",
                        badgeCount: duplicateTransactions.count,
                        transactions: duplicateTransactions,
                        duplicateIndices: Set(0 ..< duplicateTransactions.count),
                        isExpanded: $duplicatesExpanded
                    )
                }
            }
            .padding(AppSpacing.lg)

            confirmBar
        }
        .sheet(item: $sheetCreationItem) { item in
            CardEditView(mode: item.isCard
                ? .createCard(prefill: item, onCommit: handleCreationCommit)
                : .createAccount(prefill: item, onCommit: handleCreationCommit))
        }
        .onChange(of: viewModel.importSession.targetBeingCreated) { _, newValue in
            sheetCreationItem = newValue
        }
    }

    // MARK: - Computed Properties

    private var allTransactions: [ParsedTransaction] {
        viewModel.parsedStatements.flatMap(\.transactions)
    }

    private var importedTransactions: [ParsedTransaction] {
        allTransactions.enumerated().compactMap { index, txn in
            viewModel.duplicateTransactionIndices.contains(index) ? nil : txn
        }
    }

    private var duplicateTransactions: [ParsedTransaction] {
        allTransactions.enumerated().compactMap { index, txn in
            viewModel.duplicateTransactionIndices.contains(index) ? txn : nil
        }
    }

    func handleCreationCommit(_ state: TargetCreationState) {
        sheetCreationItem = nil
        viewModel.importSession.targetBeingCreated = nil
        Task {
            await viewModel.createTargetFromDetected(
                customName: state.customName,
                nickname: state.nickname,
                last4: state.last4,
                selectedBank: state.selectedBank,
                ownerName: state.cardholderName,
                accountType: state.accountType,
                cardType: state.cardType,
                cardProductId: state.cardProductId,
                encryptedCardNumber: state.encryptedCardNumber,
                linkedLedgerId: state.linkedLedgerId,
                isCard: state.isCard
            )
        }
    }
}
