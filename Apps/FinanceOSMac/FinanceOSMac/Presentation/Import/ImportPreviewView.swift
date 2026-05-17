import FinanceCore
import FinanceParsers
import SwiftUI

struct ImportPreviewView: View {
    let viewModel: ImportViewModel

    @State var showCreateSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
                }

                fileListSection()
                Divider()
                aggregatedSummarySection()
                Divider()
                targetSelectionSection
                Divider()
                aggregatedTransactionListSection()
            }
            .padding()
        }
        .sheet(isPresented: $showCreateSheet) {
            if viewModel.importSession.targetBeingCreated != nil {
                CreateNewTargetSheet(
                    state: Binding(
                        get: { viewModel.importSession.targetBeingCreated ?? TargetCreationState() },
                        set: { viewModel.importSession.targetBeingCreated = $0 }
                    ),
                    banks: viewModel.banks,
                    detectedBank: viewModel.importSession.currentParsedStatement?.bankName ?? "Unknown",
                    onCancel: {
                        showCreateSheet = false
                        viewModel.importSession.targetBeingCreated = nil
                    },
                    onCreate: {
                        Task {
                            if let state = viewModel.importSession.targetBeingCreated {
                                await viewModel.createTargetFromDetected(
                                    customName: state.customName,
                                    nickname: state.nickname,
                                    last4: state.last4,
                                    bankID: state.selectedBankID,
                                    ownerName: state.ownerName,
                                    accountType: state.accountType,
                                    cardType: state.cardType,
                                    isCard: state.isCard
                                )
                            }
                            showCreateSheet = false
                            viewModel.importSession.targetBeingCreated = nil
                        }
                    }
                )
            }
        }
    }
}
