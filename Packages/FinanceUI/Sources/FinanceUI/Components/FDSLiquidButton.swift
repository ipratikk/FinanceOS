import SwiftUI

/// Liquid Glass button with multiple variants.
///
/// Variants:
/// - `.primary` — solid accent fill, dark foreground, gleam edge
/// - `.ghost` — glass pill, primary text
/// - `.danger` — red-tinted glass pill
/// - `.link` — bare accent text with hover pill
public struct FDSLiquidButton: View {
    let title: String
    let symbol: String?
    let variant: Variant
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    public enum Variant {
        case primary, ghost, danger, link
    }

    public init(
        _ title: String,
        symbol: String? = nil,
        variant: Variant = .ghost,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.symbol = symbol
        self.variant = variant
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(foreground)
            .padding(.horizontal, variant == .link ? 0 : 12)
            .padding(.vertical, variant == .link ? 0 : 8)
            .background {
                if variant != .link {
                    background
                }
            }
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .animation(.easeInOut(duration: 0.18), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    @ViewBuilder
    private var background: some View {
        switch variant {
        case .primary:
            Capsule()
                .fill(Color(red: 1.0, green: 0.62, blue: 0.04))
                .overlay {
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.16),
                                    Color.white.opacity(0.06),
                                    .clear,
                                    Color.black.opacity(0.20)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
        case .ghost:
            Capsule()
                .fill(.regularMaterial)
                .overlay {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                }
                .overlay {
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.16),
                                    Color.white.opacity(0.06),
                                    .clear,
                                    Color.black.opacity(0.20)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
        case .danger:
            Capsule()
                .fill(Color(red: 1.0, green: 0.27, blue: 0.23).opacity(0.18))
        case .link:
            EmptyView()
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary:
            Color(red: 0.1, green: 0.1, blue: 0.11)
        case .ghost:
            Color(red: 0.945, green: 0.953, blue: 0.965)
        case .danger:
            Color(red: 1.0, green: 0.27, blue: 0.23)
        case .link:
            Color(red: 1.0, green: 0.62, blue: 0.04)
        }
    }
}
