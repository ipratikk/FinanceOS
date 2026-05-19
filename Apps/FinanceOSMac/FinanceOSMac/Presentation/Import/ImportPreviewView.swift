import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct ImportPreviewView: View {
    let viewModel: ImportViewModel

    @State private var isShowingCreationSheet = false
    @State private var sheetCreationState = TargetCreationState()
    @State private var importedExpanded = true
    @State private var duplicatesExpanded = false
    @State private var transactionListStyle: ImportTransactionListView.Style = .table

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

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ImportStatementHeading(
                        fileURLs: viewModel.fileURLs,
                        ledgerName: selectedLedgerDisplay
                    )

                    targetSelectionSection

                    if !importedTransactions.isEmpty {
                        ImportTransactionSection(
                            title: "Imported Transactions",
                            badgeCount: importedTransactions.count,
                            transactions: importedTransactions,
                            duplicateIndices: [],
                            style: $transactionListStyle,
                            isExpanded: $importedExpanded
                        )
                    }

                    if !duplicateTransactions.isEmpty {
                        ImportTransactionSection(
                            title: "Duplicate Transactions",
                            badgeCount: duplicateTransactions.count,
                            transactions: duplicateTransactions,
                            duplicateIndices: Set(0 ..< duplicateTransactions.count),
                            style: $transactionListStyle,
                            isExpanded: $duplicatesExpanded
                        )
                    }
                }
                .padding(AppSpacing.lg)
            }

            confirmBar
        }
        .sheet(isPresented: $isShowingCreationSheet) {
            CreateNewTargetSheet(
                state: $sheetCreationState,
                detectedBank: viewModel.importSession.currentParsedStatement?.bankName ?? "Unknown",
                availableAccounts: viewModel.ledgers.filter { $0.kind == .bankAccount },
                onCancel: {
                    isShowingCreationSheet = false
                    viewModel.importSession.targetBeingCreated = nil
                },
                onCreate: {
                    let state = sheetCreationState
                    isShowingCreationSheet = false
                    viewModel.importSession.targetBeingCreated = nil
                    Task {
                        await viewModel.createTargetFromDetected(
                            customName: state.customName,
                            nickname: state.nickname,
                            last4: state.last4,
                            selectedBank: state.selectedBank,
                            ownerName: state.ownerName,
                            accountType: state.accountType,
                            cardType: state.cardType,
                            cardProduct: state.cardProduct,
                            encryptedCardNumber: state.encryptedCardNumber,
                            linkedLedgerId: state.linkedLedgerId,
                            isCard: state.isCard
                        )
                    }
                }
            )
        }
        .onChange(of: viewModel.importSession.targetBeingCreated) { _, newValue in
            if let newValue {
                sheetCreationState = newValue
                isShowingCreationSheet = true
            }
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

    private var selectedLedgerDisplay: String? {
        guard let target = viewModel.selectedTarget else { return nil }
        if case let .ledger(id) = target {
            return viewModel.ledgers.first { $0.id == id }?.displayName
        }
        return nil
    }
}
