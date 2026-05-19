import FinanceCore
import FinanceParsers
import SwiftUI

struct ImportPreviewView: View {
    let viewModel: ImportViewModel
    var transactionListStyle: ImportTransactionListView.Style = .list

    @State private var isShowingCreationSheet = false
    @State private var sheetCreationState = TargetCreationState()

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
                    fileListSection()
                    Divider()
                    aggregatedSummarySection()
                    Divider()
                    targetSelectionSection
                    Divider()
                }
                .padding()
            }
            .frame(maxHeight: 200)

            aggregatedTransactionListSection()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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
}
