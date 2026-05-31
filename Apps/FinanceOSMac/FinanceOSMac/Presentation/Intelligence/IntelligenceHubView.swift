import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

struct IntelligenceHubView: View {
    let container: IntelligenceContainer
    @State private var selectedTab: IntelligenceTab = .persons
    @State private var isExporting = false
    @State private var exportResult: IntelligenceExporter.ExportResult?
    @State private var exportError: String?

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
        .navigationTitle("Financial Intelligence")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
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
                Text(
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
            if let err = exportError { Text(err) }
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
