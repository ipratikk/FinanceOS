import FinanceCore
import SwiftUI

/// Simple flat button with multiple variants.
///
/// Variants:
/// - `.primary` — solid green fill
/// - `.ghost` — outline style, light text
/// - `.danger` — red background/outline
/// - `.link` — text only
public struct FDSLiquidButton: View {
    let title: String
    let symbol: String?
    let variant: Variant
    let action: () -> Void

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
            .opacity(isPressed ? 0.8 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
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
            Capsule().fill(AppColors.accent)
        case .ghost:
            Capsule()
                .fill(AppColors.surface2)
                .overlay(Capsule().strokeBorder(AppColors.border, lineWidth: 0.5))
        case .danger:
            Capsule()
                .fill(AppColors.danger.opacity(0.15))
                .overlay(Capsule().strokeBorder(AppColors.danger.opacity(0.3), lineWidth: 0.5))
        case .link:
            EmptyView()
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary:
            AppColors.base
        case .ghost:
            AppColors.textPrimary
        case .danger:
            AppColors.danger
        case .link:
            AppColors.accent
        }
    }
}
