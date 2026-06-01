import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

struct GraphHubView: View {
    @State var viewModel: GraphViewModel

    var body: some View {
        HSplitView {
            canvasPane
            detailPane
        }
        .task { await viewModel.load() }
        .alert("Delete Node?", isPresented: Binding(
            get: { viewModel.nodeToDelete != nil },
            set: { if !$0 { viewModel.nodeToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { viewModel.nodeToDelete = nil }
            Button("Delete", role: .destructive) {
                if let node = viewModel.nodeToDelete {
                    viewModel.nodeToDelete = nil
                    Task { await viewModel.deleteNode(node) }
                }
            }
        } message: {
            if let node = viewModel.nodeToDelete { Text("Delete node \"\(node.label)\"?") }
        }
    }

    // MARK: - Canvas pane

    private var canvasPane: some View {
        VStack(spacing: 0) {
            filterBar
            Divider().opacity(0.1)
            GeometryReader { geo in
                ZStack {
                    AppColors.base
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.visibleNodes.isEmpty {
                        FDSEmptyState(
                            symbol: "point.3.connected.trianglepath.dotted",
                            title: "No Graph Data",
                            subtitle: "Run the intelligence pipeline to build the knowledge graph."
                        )
                    } else {
                        GraphCanvasView(viewModel: viewModel, canvasSize: geo.size)
                    }
                    if viewModel.isLayoutRunning {
                        VStack {
                            Spacer()
                            HStack {
                                ProgressView().controlSize(.small)
                                FDSLabel("Running layout…")
                                    .font(AppTypography.captionLg)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            .padding(AppSpacing.compact)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(AppSpacing.md)
                        }
                    }
                }
                .onAppear {
                    if !viewModel.nodePositions.isEmpty { return }
                    viewModel.runLayout(canvasSize: geo.size)
                }
            }
            graphStats
        }
        .frame(minWidth: 500)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Re-layout") {
                    viewModel.runLayout(canvasSize: CGSize(width: 900, height: 700))
                }
                .disabled(viewModel.isLayoutRunning)

                Button("Reset View") {
                    withAnimation { viewModel.panOffset = .zero }
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.compact) {
                ForEach(GraphNodeFilter.allCases, id: \.self) { filter in
                    FDSChip(filter.label, isActive: viewModel.filter == filter) {
                        viewModel.filter = filter
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.compact)
        }
    }

    private var graphStats: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.xl) {
                statTile("Nodes", value: viewModel.visibleNodes.count)
                statTile("Edges", value: viewModel.visibleEdges.count)
                statTile("Total Nodes", value: viewModel.allNodes.count)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.compact)
            .background(AppColors.surface.opacity(0.6))
            Divider().opacity(0.1)
        }
    }

    private func statTile(_ label: String, value: Int) -> some View {
        VStack(spacing: 1) {
            FDSLabel("\(value)")
                .font(AppTypography.bodySmSemibold.monospacedDigit())
                .foregroundStyle(AppColors.textPrimary)
            FDSLabel(label)
                .font(AppTypography.captionSm)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Detail pane

    private var detailPane: some View {
        VStack(spacing: 0) {
            if let node = viewModel.selectedNode {
                nodeDetailPanel(node)
            } else {
                VStack {
                    Spacer()
                    FDSLabel("Select a node")
                        .font(AppTypography.captionLg)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
        }
        .frame(minWidth: 260, maxWidth: 340)
        .background(AppColors.surface.opacity(0.5))
    }

    private func nodeDetailPanel(_ node: GraphNode) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel(node.label)
                        .font(AppTypography.bodySmSemibold)
                        .foregroundStyle(AppColors.textPrimary)
                    FDSLabel(node.nodeType.rawValue)
                        .font(AppTypography.captionLg)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)

                // Fields
                FDSCard(cornerRadius: 10, padded: false) {
                    VStack(spacing: 0) {
                        detailRow("ID", value: String(node.id.prefix(12)) + "…")
                        Divider().opacity(0.1)
                        detailRow("External ID", value: String(node.externalId.prefix(16)))
                        Divider().opacity(0.1)
                        detailRow("Type", value: node.nodeType.rawValue)
                    }
                }
                .padding(.horizontal, AppSpacing.md)

                // Edges
                if !viewModel.edgesForSelected.isEmpty {
                    FDSSectionHeader("Edges (\(viewModel.edgesForSelected.count))")
                        .padding(.horizontal, AppSpacing.md)
                    FDSCard(cornerRadius: 10, padded: false) {
                        VStack(spacing: 0) {
                            ForEach(viewModel.edgesForSelected.prefix(8)) { edge in
                                edgeRow(edge, selectedNodeId: node.id)
                                if edge.id != viewModel.edgesForSelected.prefix(8).last?.id {
                                    Divider().opacity(0.1).padding(.leading, AppSpacing.md)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }

                // Delete button
                nodeDeleteButton(node)
            }
        }
    }

    private func nodeDeleteButton(_ node: GraphNode) -> some View {
        Button(
            action: { viewModel.nodeToDelete = node },
            label: {
                Label("Delete Node", systemImage: "trash")
                    .font(AppTypography.captionLgSemibold)
                    .foregroundStyle(AppColors.debit)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.compact)
                    .background(AppColors.debit.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            }
        )
        .buttonStyle(.plain)
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.md)
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            FDSLabel(label).font(AppTypography.captionSm).foregroundStyle(.tertiary)
                .frame(width: 80, alignment: .leading)
            FDSLabel(value).font(AppTypography.captionLg).foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.compact)
    }

    private func edgeRow(_ edge: GraphEdge, selectedNodeId: String) -> some View {
        let isFrom = edge.fromNodeId == selectedNodeId
        let otherId = isFrom ? edge.toNodeId : edge.fromNodeId
        let otherLabel = viewModel.allNodes.first { $0.id == otherId }?.label ?? otherId
        return HStack(spacing: AppSpacing.compact) {
            Image(systemName: isFrom ? "arrow.right" : "arrow.left")
                .font(AppTypography.captionSm)
                .foregroundStyle(.tertiary)
            VStack(alignment: .leading, spacing: 1) {
                FDSLabel(edge.edgeType.rawValue.replacingOccurrences(of: "_", with: " "))
                    .font(AppTypography.captionSmSemibold).foregroundStyle(.tertiary)
                FDSLabel(String(otherLabel.prefix(24)))
                    .font(AppTypography.captionLg).foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Button(
                action: { viewModel.edgeToDelete = edge },
                label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(AppTypography.captionSm).foregroundStyle(AppColors.debit.opacity(0.6))
                }
            )
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.compact)
    }
}

extension GraphEdge: @retroactive Identifiable {}
