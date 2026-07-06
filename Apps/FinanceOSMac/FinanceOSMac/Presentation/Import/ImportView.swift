import FinanceCore
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
            HStack {
                FDSLabel("Import Statement")
                    .font(AppTypography.headingXL)
                    .foregroundColor(AppColors.Text.primary)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            Group {
                switch viewModel.phase {
                case .idle:
                    idleContent
                case .previewing:
                    previewingContent
                case .readyToImport:
                    readyToImportContent
                case .importing:
                    importingContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(AppSpacing.x6l)
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.phase)
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
            if let target = navigator.pendingImportTarget {
                viewModel.selectedTarget = target
                navigator.pendingImportTarget = nil
            }
            navigator.pendingImportSource = nil
            Task {
                await viewModel.loadTargetsOnAppear()
            }
        }
        .sheet(
            item: $viewModel.pendingPasswordRequest,
            onDismiss: { viewModel.cancelPendingPasswordRequest() },
            content: { request in
                PasswordPromptSheet(
                    filename: request.filename,
                    isPasswordInvalid: request.isRetry,
                    onCancel: request.onCancel,
                    onSubmit: request.onSubmit
                )
            }
        )
    }
}

#Preview {
    ImportView(
        viewModel: ImportViewModel(
            graphQLClient: ApolloGraphQLClient()
        )
    )
}
