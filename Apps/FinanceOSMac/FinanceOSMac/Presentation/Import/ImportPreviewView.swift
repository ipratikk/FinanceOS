import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct ImportPreviewView: View {
    let viewModel: ImportViewModel

    @State private var isShowingCreationSheet = false
    @State private var sheetCreationState = TargetCreationState()
    @State private var importedExpanded = false
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

            VStack(spacing: 0) {
                // New Transactions Section
                if !importedTransactions.isEmpty {
                    sectionHeader(
                        title: "New Transactions",
                        badgeCount: importedTransactions.count,
                        onViewAllToggle: { importedExpanded.toggle() }
                    )
                    Divider()

                    ScrollView {
                        ImportTransactionListView(
                            transactions: importedTransactions,
                            duplicateIndices: [],
                            style: transactionListStyle,
                            scrollable: false,
                            rowLimit: importedExpanded ? nil : 5
                        )
                        .padding(AppSpacing.lg)
                    }
                }

                // Already Imported Section
                if !duplicateTransactions.isEmpty {
                    if !importedTransactions.isEmpty {
                        Divider()
                    }

                    sectionHeader(
                        title: "Already imported",
                        badgeCount: duplicateTransactions.count,
                        onViewAllToggle: { duplicatesExpanded.toggle() }
                    )
                    Divider()

                    ScrollView {
                        ImportTransactionListView(
                            transactions: duplicateTransactions,
                            duplicateIndices: Set(0 ..< duplicateTransactions.count),
                            style: transactionListStyle,
                            scrollable: false,
                            rowLimit: duplicatesExpanded ? nil : 5
                        )
                        .padding(AppSpacing.lg)
                    }
                }
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

    // MARK: - Section Header

    private func sectionHeader(
        title: String,
        badgeCount: Int,
        onViewAllToggle: @escaping () -> Void
    ) -> some View {
        HStack(spacing: AppSpacing.md) {
            HStack(spacing: 8) {
                Text(title)
                    .font(AppTypography.headingSmall)
                    .foregroundColor(DesignTokens.Text.primary)

                FBadge(String(badgeCount), color: .blue)
            }

            Spacer()

            HStack(spacing: 4) {
                Button(action: { transactionListStyle = .list }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14, weight: transactionListStyle == .list ? .semibold : .regular))
                        .foregroundColor(
                            transactionListStyle == .list ? AppColors.accent : DesignTokens.Text.secondary
                        )
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: 16)

                Button(action: { transactionListStyle = .table }) {
                    Image(systemName: "tablecells")
                        .font(.system(size: 14, weight: transactionListStyle == .table ? .semibold : .regular))
                        .foregroundColor(
                            transactionListStyle == .table ? AppColors.accent : DesignTokens.Text.secondary
                        )
                }
                .buttonStyle(.plain)
            }

            Button(action: onViewAllToggle) {
                Text(
                    (title == "New Transactions" ? importedExpanded : duplicatesExpanded) ? "Show Less" : "View All"
                )
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.accent)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(AppSpacing.md)
        .background(DesignTokens.Background.surfaceGlass)
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
