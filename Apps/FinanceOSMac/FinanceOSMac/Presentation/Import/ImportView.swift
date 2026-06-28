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
                onStepSelect: { step in
                    switch step {
                    case .source:
                        viewModel.resetToSource()
                    case .upload:
                        if viewModel.currentStep == .review {
                            viewModel.backToUpload()
                        }
                    case .review:
                        break
                    }
                }
            )

            // Step content
            Group {
                switch viewModel.currentStep {
                case .source:
                    FDSCard(content: {
                        sourceStep
                            .padding(AppSpacing.xl)
                    })
                case .upload:
                    uploadStep
                case .review:
                    reviewStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(AppSpacing.x6l)
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.currentStep)
        .onChange(of: viewModel.lastImportResult) { _, newValue in
            if let result = newValue {
                navigator.toastPresenter.show(
                    message: "Imported \(result.inserted) transaction\(result.inserted == 1 ? "" : "s")" +
                        (result.skipped > 0 ? " · \(result.skipped) skipped" : ""),
                    type: .success,
                    position: .top,
                    horizontalAlignment: .trailing,
                    duration: 4.0
                )
            }
        }
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
}

#Preview {
    ImportView(
        viewModel: ImportViewModel(
            graphQLClient: ApolloGraphQLClient()
        )
    )
}
