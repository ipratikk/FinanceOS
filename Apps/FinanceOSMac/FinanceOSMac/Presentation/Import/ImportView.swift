import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct ImportView: View {
    @State var viewModel: ImportViewModel

    init(viewModel: ImportViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    @Environment(AppNavigator.self) private var navigator

    var body: some View {
        VStack(spacing: 0) {
            // Stepper at top
            ImportStepper(
                step: viewModel.currentStep,
                onStartOver: viewModel.resetToSource
            )
            .padding(AppSpacing.lg)

            // Step content
            Group {
                switch viewModel.currentStep {
                case .source:
                    sourceStep
                case .upload:
                    uploadStep
                case .review:
                    reviewStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Success banner
            if let result = viewModel.lastImportResult {
                importSuccessBanner(result: result)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.currentStep)
        .onAppear {
            if let source = navigator.pendingImportSource {
                viewModel.selectSourceAndAdvance(source)
                navigator.pendingImportSource = nil
            }
            navigator.pendingImportTarget = nil
            Task {
                await viewModel.loadTargetsOnAppear()
            }
        }
    }

    private func importSuccessBanner(result: ImportResult) -> some View {
        HStack(spacing: AppSpacing.compact) {
            Image(systemName: "checkmark.circle.fill")
                .bodyMedium()
                .foregroundStyle(AppColors.credit)
            Text(
                "Imported \(result.inserted) transaction\(result.inserted == 1 ? "" : "s")" +
                    (result.skipped > 0 ? " · \(result.skipped) skipped" : "")
            )
            .caption()
            .foregroundStyle(.primary)
            Spacer()
            Button(action: { viewModel.lastImportResult = nil }) {
                Image(systemName: "xmark")
                    .font(AppTypography.labelSemibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.compact)
        .background {
            Capsule(style: .continuous)
                .fill(.thickMaterial)
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(AppColors.credit.opacity(0.3), lineWidth: 0.5)
                }
        }
        .padding(AppSpacing.md)
    }
}

#Preview {
    let mockRepository = MockTransactionRepository()
    let mockPipeline = TransactionImportPipeline(
        repository: mockRepository
    )

    ImportView(
        viewModel: ImportViewModel(
            transactionImportPipeline: mockPipeline,
            bankRepository: MockBankRepository(),
            ledgerRepository: MockLedgerRepository(),
            transactionRepository: mockRepository
        )
    )
}
