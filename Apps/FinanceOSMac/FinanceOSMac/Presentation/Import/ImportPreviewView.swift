import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct ImportPreviewView: View {
    let viewModel: ImportViewModel

    @State private var sheetCreationItem: TargetCreationState?
    @State private var importedExpanded = false
    @State private var duplicatesExpanded = false
    @State var isTargetMenuOpen = false

    var body: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    FDSLabel(error)
                        .font(AppTypography.captionLg)
                        .foregroundStyle(AppColors.Text.tertiary)
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
            FDSCard(padded: false) {
                HStack(spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        FDSLabel("Review parsed transactions")
                            .font(AppTypography.headingMd)
                            .foregroundColor(AppColors.accent)

                        if !viewModel.parsedStatements.isEmpty {
                            let totalTxns = viewModel.parsedStatements.flatMap(\.transactions).count
                            let newCount = totalTxns - viewModel.duplicateTransactionIndices.count
                            let dupCount = viewModel.alreadyInDBIndices.count
                            let fileCount = viewModel.parsedStatements.count
                            let fileLabel = fileCount == 1
                                ? (viewModel.fileURLs.first?.lastPathComponent ?? "1 file")
                                : "\(fileCount) files"
                            FDSLabel("\(fileLabel) · \(newCount) new · \(dupCount) already imported")
                                .font(AppTypography.labelSmall)
                                .foregroundColor(AppColors.Text.tertiary)
                        }
                    }

                    Spacer()

                    targetSelectionMenu
                }
                .padding(AppSpacing.lg)
            }

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if importedTransactions.isEmpty, !duplicateTransactions.isEmpty {
                    allCaughtUpBanner
                }

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

            Spacer()
            confirmBar
        }
        .onAppear {
            if importedTransactions.isEmpty, !duplicateTransactions.isEmpty {
                duplicatesExpanded = true
            }
        }
        .sheet(item: $sheetCreationItem) { item in
            if item.isCard {
                CardEditView(mode: .createCard(prefill: item, onCommit: handleCreationCommit))
            } else {
                CardEditView(mode: .createAccount(prefill: item, onCommit: handleCreationCommit))
            }
        }
        .onChange(of: viewModel.importSession.targetBeingCreated) { _, newValue in
            sheetCreationItem = newValue
        }
    }

    // MARK: - Computed Properties

    private var allCaughtUpBanner: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppColors.success)
            FDSLabel("All transactions already imported — nothing new to add.")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.Text.secondary)
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.success.opacity(0.08))
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(AppColors.success.opacity(0.2), lineWidth: 1)
        )
    }

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
            viewModel.alreadyInDBIndices.contains(index) ? txn : nil
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
