import FinanceCore
import SwiftUI

/// Liquid Glass button with multiple variants.
///
/// Variants:
/// - `.primary` — emerald fill (AppColors.accentGreen) with gleam edge
/// - `.ghost`   — .regularMaterial glass pill, primary text
/// - `.danger`  — DesignTokens.Semantic.danger-tinted glass pill
/// - `.link`    — bare AppColors.accent text with hover pill
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
        Button(action: action, label: {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(AppTypography.bodySmSemibold)
                }
                FDSLabel(title)
                    .font(AppTypography.bodySmSemibold)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, variant == .link ? 0 : 12)
            .padding(.vertical, variant == .link ? 0 : 8)
            .background {
                if variant != .link {
                    buttonBackground
                }
            }
            .scaleEffect(isPressed ? 0.97 : 1.0)
        })
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(AppAnimation.hover, value: isHovered)
        .animation(AppAnimation.easeFast, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Background

    //
    // primary  — AppColors.accentGreen solid capsule with glass gleam border
    // ghost    — .regularMaterial capsule with glass tint and gleam border
    // danger   — DesignTokens.Semantic.danger at 18% opacity
    // link     — no background

    @ViewBuilder
    private var buttonBackground: some View {
        switch variant {
        case .primary:
            Capsule()
                .fill(AppColors.accentGreen)
                .overlay {
                    Capsule()
                        .strokeBorder(gleamGradient, lineWidth: 1)
                }
        case .ghost:
            Capsule()
                .fill(.regularMaterial)
                .overlay {
                    Capsule()
                        .fill(DesignTokens.Background.surfaceGlass)
                }
                .overlay {
                    Capsule()
                        .strokeBorder(gleamGradient, lineWidth: 1)
                }
        case .danger:
            Capsule()
                .fill(AppColors.danger.opacity(0.18))
        case .link:
            EmptyView()
        }
    }

    // MARK: - Foreground Colors

    //
    // primary  — near-black text on bright green fill
    // ghost    — DesignTokens.Text.primary (near-white)
    // danger   — AppColors.danger (red)
    // link     — AppColors.accent (emerald)

    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return Color(red: 0.1, green: 0.1, blue: 0.11)
        case .ghost:
            return DesignTokens.Text.primary
        case .danger:
            return AppColors.danger
        case .link:
            return AppColors.accent
        }
    }

    // MARK: - Shared Gleam Border Gradient

    private var gleamGradient: LinearGradient {
        LinearGradient(
            colors: [
                DesignTokens.Edge.topGleam,
                DesignTokens.Edge.topGleamMid,
                .clear,
                DesignTokens.Edge.bottomShadow
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
