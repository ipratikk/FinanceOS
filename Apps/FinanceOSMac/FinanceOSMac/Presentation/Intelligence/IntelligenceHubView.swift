import FinanceCore
import FinanceIntelligence
import FinanceOSAPI
import FinanceUI
import SwiftUI

struct IntelligenceHubView: View {
    let container: IntelligenceContainer
    @State private var selectedTab: IntelligenceTab = .persons
    @State private var isExporting = false
    @State private var exportResult: IntelligenceExporter.ExportResult?
    @State private var exportError: String?
    @State private var isTraining = false
    @State private var trainExampleCount = 0
    @State private var trainError: String?
    @State private var trainResult: ClassificationEvaluationResult?
    @Environment(\.transactionIntelligence) private var intelligence

    enum IntelligenceTab: Int {
        case persons = 0, relationships, patterns, graph
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            PersonsView(
                viewModel: PersonsViewModel(repo: container.personRepository)
            )
            .tabItem { Label("Persons", systemImage: "person.2") }
            .tag(IntelligenceTab.persons)

            RelationshipsView(
                viewModel: RelationshipsViewModel(
                    repo: container.relationshipRepository,
                    personRepo: container.personRepository
                )
            )
            .tabItem { Label("Relationships", systemImage: "arrow.triangle.2.circlepath") }
            .tag(IntelligenceTab.relationships)

            RecurringPatternsView(
                viewModel: RecurringPatternsViewModel(repo: container.recurringPatternRepository)
            )
            .tabItem { Label("Patterns", systemImage: "arrow.trianglehead.2.clockwise") }
            .tag(IntelligenceTab.patterns)

            GraphHubView(
                viewModel: GraphViewModel(repo: container.graphRepository)
            )
            .tabItem { Label("Graph", systemImage: "point.3.connected.trianglepath.dotted") }
            .tag(IntelligenceTab.graph)
        }
        .background(AppColors.base)
        .overlay { if isTraining { trainingOverlay } }
        .navigationTitle("Financial Intelligence")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: startTraining) {
                    Label("Train Model", systemImage: "brain.head.profile")
                }
                .disabled(isTraining)
                .help("Bulk-trains the on-device classifier from all categorized transactions via MLUpdateTask")
                if isExporting {
                    ProgressView().controlSize(.small)
                } else {
                    Button(action: startExport) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                }
                Label("Developer", systemImage: "hammer.fill")
                    .font(AppTypography.captionLg)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .alert("Model Trained", isPresented: Binding(
            get: { trainResult != nil },
            set: { if !$0 { trainResult = nil } }
        )) {
            Button("OK") { trainResult = nil }
        } message: {
            if let res = trainResult { trainResultMessage(res) }
        }
        .alert("Training Failed", isPresented: Binding(
            get: { trainError != nil },
            set: { if !$0 { trainError = nil } }
        )) {
            Button("OK") { trainError = nil }
        } message: {
            if let err = trainError { FDSLabel(err) }
        }
        .alert("Export Complete", isPresented: Binding(
            get: { exportResult != nil },
            set: { if !$0 { exportResult = nil } }
        )) {
            Button("Reveal in Finder") {
                if let url = exportResult?.folder {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
                }
                exportResult = nil
            }
            Button("OK") { exportResult = nil }
        } message: {
            if let result = exportResult {
                FDSLabel(
                    "Exported \(result.personCount) persons, \(result.relationshipCount) relationships, " +
                        "\(result.patternCount) patterns, \(result.nodeCount) nodes, \(result.edgeCount) edges."
                )
            }
        }
        .alert("Export Failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK") { exportError = nil }
        } message: {
            if let err = exportError { FDSLabel(err) }
        }
    }

    private var trainingOverlay: some View {
        ZStack {
            AppColors.base.opacity(0.85).ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                ProgressView()
                    .controlSize(.large)
                    .tint(AppColors.accent)
                VStack(spacing: AppSpacing.compact) {
                    FDSLabel("Training On-Device Classifier")
                        .font(AppTypography.bodyMdSemibold)
                        .foregroundStyle(AppColors.textPrimary)
                    FDSLabel("\(trainExampleCount) transactions · CoreML MLUpdateTask")
                        .font(AppTypography.captionLg)
                        .foregroundStyle(AppColors.textSecondary)
                    FDSLabel("This may take a moment…")
                        .font(AppTypography.captionLg)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(AppSpacing.xl)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        }
    }

    private func trainResultMessage(_ res: ClassificationEvaluationResult) -> some View {
        let covPct = Int(res.coverage * 100)
        let accuracyLine: String = res.hasReliableMetrics
            ? "Validation accuracy: \(Int(res.accuracy * 100))% · F1: \(String(format: "%.2f", res.f1Macro))"
            : "Insufficient validation data — import more labeled statements."
        let ready = res.hasReliableMetrics && res.accuracy >= 0.90 && res.coverage >= 0.85
        let statusLine = ready
            ? "Model is ready — keyword rules can be pruned."
            : "Import more statements and re-train."
        let msg = "Validated on \(res.validationCount) of \(res.exampleCount) examples.\n" +
            "Coverage: \(covPct)%  \(accuracyLine)\n\(statusLine)"
        return FDSLabel(msg)
    }

    private func startTraining() {
        guard let service = intelligence else { return }
        isTraining = true
        Task {
            do {
                let txnData = try await AppContainer.shared.graphQLClient.fetch(
                    query: GetTransactionsQuery(ledgerId: .none, filter: .none, limit: .none)
                )
                let transactions = txnData.transactions.map(GraphQLMappings.mapTransaction)
                let examples = transactions.compactMap { txn -> (text: String, categoryId: String)? in
                    guard let cat = txn.categoryId, !cat.isEmpty, cat != "uncategorized" else { return nil }
                    return (text: txn.description, categoryId: cat)
                }
                trainExampleCount = examples.count
                try await service.trainClassifier(examples: examples)
                trainResult = await service.evaluateClassifier(examples: examples)
            } catch {
                trainError = error.localizedDescription
            }
            isTraining = false
        }
    }

    private func startExport() {
        guard let folder = IntelligenceExporter.chooseDestinationFolder() else { return }
        isExporting = true
        Task {
            do {
                exportResult = try await IntelligenceExporter.exportAll(container: container, to: folder)
            } catch {
                exportError = error.localizedDescription
            }
            isExporting = false
        }
    }
}
