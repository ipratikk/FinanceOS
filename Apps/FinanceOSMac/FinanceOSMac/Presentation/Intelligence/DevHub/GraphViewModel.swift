// swiftlint:disable identifier_name
import FinanceCore
import FinanceIntelligence
import Foundation
import SwiftUI

// MARK: - Node type filter

enum GraphNodeFilter: String, CaseIterable {
    case all, person, merchant, category, account, transaction, institution, recurringPattern
    var label: String {
        rawValue == "all" ? "All" : rawValue.capitalized
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class GraphViewModel {
    private let repo: any GraphRepository

    var allNodes: [GraphNode] = []
    var allEdges: [GraphEdge] = []
    var nodePositions: [String: CGPoint] = [:]
    var selectedNodeId: String?
    var panOffset: CGSize = .zero
    var filter: GraphNodeFilter = .all
    var nodeToDelete: GraphNode?
    var edgeToDelete: GraphEdge?
    var isLoading = false
    var isLayoutRunning = false
    var errorMessage: String?

    private var layoutTask: Task<Void, Never>?

    init(repo: any GraphRepository) {
        self.repo = repo
    }

    var visibleNodes: [GraphNode] {
        guard filter != .all else { return allNodes }
        return allNodes.filter { $0.nodeType.rawValue == filter.rawValue }
    }

    var visibleEdges: [GraphEdge] {
        let ids = Set(visibleNodes.map(\.id))
        return allEdges.filter { ids.contains($0.fromNodeId) && ids.contains($0.toNodeId) }
    }

    var selectedNode: GraphNode? {
        allNodes.first { $0.id == selectedNodeId }
    }

    var edgesForSelected: [GraphEdge] {
        guard let id = selectedNodeId else { return [] }
        return allEdges.filter { $0.fromNodeId == id || $0.toNodeId == id }
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            allNodes = try await repo.allNodes(limit: 500)
            allEdges = try await repo.allEdges(limit: 1000)
            if nodePositions.isEmpty { assignInitialPositions(canvasSize: CGSize(width: 900, height: 700)) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Layout

    func runLayout(canvasSize: CGSize) {
        layoutTask?.cancel()
        isLayoutRunning = true
        let nodes = visibleNodes
        let edges = visibleEdges
        var initialPositions = nodePositions
        nodes.forEach { if initialPositions[$0.id] == nil { initialPositions[$0.id] = randomPosition(in: canvasSize) } }
        let snapshotPositions = initialPositions

        layoutTask = Task.detached(priority: .userInitiated) { [weak self] in
            var pos = snapshotPositions
            var velocities: [String: CGPoint] = [:]
            let repK: Double = 6000
            let attK: Double = 0.05
            let ideal: Double = 110
            let damp: Double = 0.80

            for _ in 0 ..< 80 {
                var forces: [String: CGPoint] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, .zero) })
                for i in nodes.indices {
                    for j in nodes.indices where j > i {
                        guard let pi = pos[nodes[i].id], let pj = pos[nodes[j].id] else { continue }
                        let dx = pi.x - pj.x, dy = pi.y - pj.y
                        let dist = max(sqrt(dx * dx + dy * dy), 1.0)
                        let force = repK / (dist * dist)
                        let fx = force * dx / dist, fy = force * dy / dist
                        forces[nodes[i].id]! = CGPoint(x: forces[nodes[i].id]!.x + fx, y: forces[nodes[i].id]!.y + fy)
                        forces[nodes[j].id]! = CGPoint(x: forces[nodes[j].id]!.x - fx, y: forces[nodes[j].id]!.y - fy)
                    }
                }
                for edge in edges {
                    guard let pf = pos[edge.fromNodeId], let pt = pos[edge.toNodeId] else { continue }
                    let dx = pt.x - pf.x, dy = pt.y - pf.y
                    let dist = max(sqrt(dx * dx + dy * dy), 1.0)
                    let force = attK * (dist - ideal)
                    let fx = force * dx / dist, fy = force * dy / dist
                    forces[edge.fromNodeId]! = CGPoint(
                        x: (forces[edge.fromNodeId]?.x ?? 0) + fx,
                        y: (forces[edge.fromNodeId]?.y ?? 0) + fy
                    )
                    forces[edge.toNodeId]! = CGPoint(
                        x: (forces[edge.toNodeId]?.x ?? 0) - fx,
                        y: (forces[edge.toNodeId]?.y ?? 0) - fy
                    )
                }
                for node in nodes {
                    var v = velocities[node.id] ?? .zero
                    let f = forces[node.id] ?? .zero
                    v = CGPoint(x: (v.x + f.x) * damp, y: (v.y + f.y) * damp)
                    velocities[node.id] = v
                    if let cur = pos[node.id] { pos[node.id] = CGPoint(x: cur.x + v.x, y: cur.y + v.y) }
                }
            }
            // Center and scale
            let xs = pos.values.map(\.x), ys = pos.values.map(\.y)
            if let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() {
                let cx = (minX + maxX) / 2, cy = (minY + maxY) / 2
                let targetCX = canvasSize.width / 2, targetCY = canvasSize.height / 2
                let scaleX = (canvasSize.width * 0.85) / max(maxX - minX, 1)
                let scaleY = (canvasSize.height * 0.85) / max(maxY - minY, 1)
                let scale = min(min(scaleX, scaleY), 1.5)
                for k in pos.keys {
                    pos[k] = CGPoint(
                        x: (pos[k]!.x - cx) * scale + targetCX,
                        y: (pos[k]!.y - cy) * scale + targetCY
                    )
                }
            }
            let finalPositions = pos
            await MainActor.run { [weak self] in
                self?.nodePositions = finalPositions
                self?.isLayoutRunning = false
            }
        }
    }

    // MARK: - Mutations

    func moveNode(id: String, to position: CGPoint) {
        nodePositions[id] = position
    }

    func deleteNode(_ node: GraphNode) async {
        do {
            try await repo.deleteNode(id: node.id)
            allNodes.removeAll { $0.id == node.id }
            allEdges.removeAll { $0.fromNodeId == node.id || $0.toNodeId == node.id }
            nodePositions.removeValue(forKey: node.id)
            if selectedNodeId == node.id { selectedNodeId = nil }
        } catch { errorMessage = error.localizedDescription }
    }

    func deleteEdge(_ edge: GraphEdge) async {
        do {
            try await repo.deleteEdge(id: edge.id)
            allEdges.removeAll { $0.id == edge.id }
        } catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Private helpers

    private func assignInitialPositions(canvasSize: CGSize) {
        let cols = max(Int(sqrt(Double(allNodes.count))), 1)
        let padding = 80.0
        let cellW = (canvasSize.width - padding * 2) / Double(cols)
        let cellH = (canvasSize.height - padding * 2) / Double(max(allNodes.count / cols + 1, 1))
        for (i, node) in allNodes.enumerated() {
            let col = i % cols, row = i / cols
            nodePositions[node.id] = CGPoint(
                x: padding + Double(col) * cellW + cellW / 2,
                y: padding + Double(row) * cellH + cellH / 2
            )
        }
    }

    private func randomPosition(in size: CGSize) -> CGPoint {
        CGPoint(
            x: Double.random(in: 80 ... (size.width - 80)),
            y: Double.random(in: 80 ... (size.height - 80))
        )
    }
}
