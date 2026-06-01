import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

struct GraphCanvasView: View {
    @Bindable var viewModel: GraphViewModel
    let canvasSize: CGSize

    @State private var dragNodeId: String?
    @State private var canvasPanStart: CGSize = .zero

    var body: some View {
        Canvas { context, _ in
            drawEdges(context: context)
            drawNodes(context: context)
        }
        .gesture(dragGesture)
        .onTapGesture(perform: handleTap)
    }

    // MARK: - Drawing

    private func drawEdges(context: GraphicsContext) {
        for edge in viewModel.visibleEdges {
            guard let from = viewModel.nodePositions[edge.fromNodeId]?.translated(by: viewModel.panOffset),
                  let to = viewModel.nodePositions[edge.toNodeId]?.translated(by: viewModel.panOffset)
            else { continue }
            var path = Path()
            path.move(to: from)
            path.addLine(to: to)
            let width = CGFloat(edge.weight).clamped(to: 0.4 ... 2.5)
            let alpha = CGFloat(edge.observationCount).clamped(to: 0.15 ... 0.6) / 0.6 * 0.4 + 0.15
            context.stroke(path, with: .color(AppColors.textPrimary.opacity(alpha)), lineWidth: width)
        }
    }

    private func drawNodes(context: GraphicsContext) {
        for node in viewModel.visibleNodes {
            guard let pos = viewModel.nodePositions[node.id]?.translated(by: viewModel.panOffset) else { continue }
            let radius = nodeRadius(node)
            let rect = CGRect(x: pos.x - radius, y: pos.y - radius, width: radius * 2, height: radius * 2)
            let color = nodeColor(node)

            // Fill
            context.fill(Ellipse().path(in: rect), with: .color(color.opacity(0.85)))
            // Border
            context.stroke(
                Ellipse().path(in: rect.insetBy(dx: -0.5, dy: -0.5)),
                with: .color(color.opacity(0.4)),
                lineWidth: 0.5
            )
            // Selection ring
            if viewModel.selectedNodeId == node.id {
                context.stroke(
                    Ellipse().path(in: rect.insetBy(dx: -3, dy: -3)),
                    with: .color(AppColors.textPrimary.opacity(0.9)),
                    lineWidth: 1.5
                )
            }
            // Label (skip transaction nodes — too small and too many)
            if node.nodeType != .transaction, radius >= 8 {
                let label = String(node.label.prefix(18))
                context.draw(
                    Text(label)
                        // swiftlint:disable:next hardcoded_font_system
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary.opacity(0.85)),
                    at: CGPoint(x: pos.x, y: pos.y + radius + 9)
                )
            }
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                if dragNodeId == nil {
                    // Determine if we started on a node
                    let hit = hitTest(location: value.startLocation)
                    dragNodeId = hit
                }
                if let nid = dragNodeId {
                    viewModel.moveNode(id: nid, to: value.location.translated(by: viewModel.panOffset.negated()))
                } else {
                    // Pan canvas
                    viewModel.panOffset = CGSize(
                        width: canvasPanStart.width + value.translation.width,
                        height: canvasPanStart.height + value.translation.height
                    )
                }
            }
            .onEnded { _ in
                if dragNodeId == nil { canvasPanStart = viewModel.panOffset }
                dragNodeId = nil
            }
    }

    private func handleTap(location: CGPoint) {
        let hit = hitTest(location: location)
        viewModel.selectedNodeId = hit
    }

    private func hitTest(location: CGPoint) -> String? {
        for node in viewModel.visibleNodes.reversed() {
            guard let pos = viewModel.nodePositions[node.id]?.translated(by: viewModel.panOffset) else { continue }
            let radius = nodeRadius(node) + 4
            let dx = location.x - pos.x, dy = location.y - pos.y
            if dx * dx + dy * dy <= radius * radius { return node.id }
        }
        return nil
    }

    // MARK: - Style helpers

    private func nodeRadius(_ node: GraphNode) -> CGFloat {
        switch node.nodeType {
        case .transaction: return 4
        case .category: return 9
        default: return 12
        }
    }

    private func nodeColor(_ node: GraphNode) -> Color {
        switch node.nodeType {
        case .person: return Color(red: 0.25, green: 0.55, blue: 1.0)
        case .merchant: return Color(red: 1.0, green: 0.55, blue: 0.15)
        case .category: return Color(red: 0.18, green: 0.78, blue: 0.45)
        case .transaction: return AppColors.textPrimary.opacity(0.25)
        case .account: return Color(red: 1.0, green: 0.80, blue: 0.10)
        case .institution: return Color(red: 0.75, green: 0.35, blue: 0.95)
        case .recurringPattern: return Color(red: 0.0, green: 0.85, blue: 0.85)
        }
    }
}

// MARK: - CGPoint helpers

private extension CGPoint {
    func translated(by offset: CGSize) -> CGPoint {
        CGPoint(x: x + offset.width, y: y + offset.height)
    }

    func translated(by offset: CGPoint) -> CGPoint {
        CGPoint(x: x + offset.x, y: y + offset.y)
    }
}

private extension CGSize {
    func negated() -> CGSize {
        CGSize(width: -width, height: -height)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
