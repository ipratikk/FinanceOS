import FinanceCore
import SwiftUI

// MARK: - Hit Target Enforcement Modifier

/// Enforces minimum 44pt touch target size while preserving visual size.
/// Used for icon buttons and interactive elements.
public struct HitTargetModifier: ViewModifier {
    private let minSize: CGFloat = AppSpacing.hitTarget

    public func body(content: Content) -> some View {
        content
            .frame(minWidth: minSize, minHeight: minSize)
    }
}

public extension View {
    /// Ensures this view has minimum 44pt touch target in both dimensions.
    func minHitTarget() -> some View {
        modifier(HitTargetModifier())
    }
}

// MARK: - Full-Width Tap Target Modifier

/// Makes entire container tappable, not just child content.
/// Essential for rows, cards, pills.
public struct FullWidthTapModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
    }
}

public extension View {
    /// Makes entire container (including padding) tappable.
    func fullWidthTap() -> some View {
        modifier(FullWidthTapModifier())
    }
}

// MARK: - Accessible Icon Button Modifier

/// Creates accessible icon-only button with proper hit target and labels.
public struct AccessibleIconButtonModifier: ViewModifier {
    let label: String
    let hint: String?

    public func body(content: Content) -> some View {
        content
            .minHitTarget()
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(hint ?? "")
    }
}

public extension View {
    /// Makes icon button accessible with label and optional hint.
    func accessibleIconButton(label: String, hint: String? = nil) -> some View {
        modifier(AccessibleIconButtonModifier(label: label, hint: hint))
    }
}

// MARK: - Accessible Interactive Container Modifier

/// Marks container as interactive for accessibility (rows, cards, etc.)
public struct AccessibleInteractiveModifier: ViewModifier {
    let label: String?
    let isSelected: Bool

    public func body(content: Content) -> some View {
        content
            .fullWidthTap()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label ?? "")
            .accessibility(addTraits: isSelected ? [.isSelected] : [])
    }
}

public extension View {
    /// Marks container as interactive with accessibility semantics.
    func accessibleInteractive(label: String? = nil, isSelected: Bool = false) -> some View {
        modifier(AccessibleInteractiveModifier(label: label, isSelected: isSelected))
    }
}

// MARK: - Dynamic Type Support Modifier

/// Ensures text respects Dynamic Type settings without excessive scaling.
public struct DynamicTypeSafeModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .lineLimit(3)
            .allowsTightening(true)
    }
}

public extension View {
    /// Makes text Dynamic Type safe (scales but remains readable).
    func dynamicTypeSafe() -> some View {
        modifier(DynamicTypeSafeModifier())
    }
}
