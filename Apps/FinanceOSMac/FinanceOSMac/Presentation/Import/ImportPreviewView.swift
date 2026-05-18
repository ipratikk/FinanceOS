import FinanceCore
import FinanceParsers
import SwiftUI

struct ImportPreviewView: View {
    let viewModel: ImportViewModel

    var targetBeingCreatedBinding: Binding<TargetCreationState?> {
        Binding(
            get: { viewModel.importSession.targetBeingCreated },
            set: { viewModel.importSession.targetBeingCreated = $0 }
        )
    }

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
        .sheet(item: targetBeingCreatedBinding) { _ in
            CreateNewTargetSheet(
                state: Binding(
                    get: { viewModel.importSession.targetBeingCreated ?? TargetCreationState() },
                    set: { viewModel.importSession.targetBeingCreated = $0 }
                ),
                detectedBank: viewModel.importSession.currentParsedStatement?.bankName ?? "Unknown",
                onCancel: {
                    viewModel.importSession.targetBeingCreated = nil
                },
                onCreate: {
                    Task {
                        if let state = viewModel.importSession.targetBeingCreated {
                            await viewModel.createTargetFromDetected(
                                customName: state.customName,
                                nickname: state.nickname,
                                last4: state.last4,
                                selectedBank: state.selectedBank,
                                ownerName: state.ownerName,
                                accountType: state.accountType,
                                cardType: state.cardType,
                                cardProduct: state.cardProduct,
                                isCard: state.isCard
                            )
                        }
                        viewModel.importSession.targetBeingCreated = nil
                    }
                }
            )
        }
    }
}
