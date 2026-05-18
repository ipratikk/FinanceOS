import FinanceCore
import SwiftUI

/// Native macOS-style button with liquid material backing.
///
/// Variants:
/// - `.primary` — filled accent, key action
/// - `.secondary` — material chip, neutral
/// - `.subtle` — text-only with hover, low emphasis
/// - `.destructive` — red accent
public struct FDSLiquidButton: View {
    let title: String
    let symbol: String?
    let variant: Variant
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    public enum Variant {
        case primary, secondary, subtle, destructive
    }

    public init(
        _ title: String,
        symbol: String? = nil,
        variant: Variant = .secondary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.symbol = symbol
        self.variant = variant
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.compact) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.compact)
            .background {
                background
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 0.5)
            }
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isHovered)
        .animation(.spring(response: 0.18, dampingFraction: 0.7), value: isPressed)
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
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppColors.accentBlue,
                            AppColors.accentCyan
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(isHovered ? 1.0 : 0.9)
        case .secondary:
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(AppColors.accentCyan.opacity(isHovered ? 0.1 : 0.0))
                }
        case .subtle:
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .fill(Color.white.opacity(isHovered ? 0.06 : 0.0))
        case .destructive:
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .fill(AppColors.danger.opacity(isHovered ? 0.25 : 0.15))
        }
    }

    private var stroke: Color {
        switch variant {
        case .primary:
            AppColors.accentCyan.opacity(0.3)
        case .destructive:
            AppColors.danger.opacity(0.2)
        case .secondary:
            AppColors.accentCyan.opacity(0.12)
        case .subtle:
            .clear
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary:
            .black
        case .secondary, .subtle:
            AppColors.textPrimary
        case .destructive:
            AppColors.danger
        }
    }
}
