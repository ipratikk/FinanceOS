import FinanceCore
import SwiftUI

/// Pins a footer view below scrollable content, above the safe area.
///
/// Draws a subtle separator between content and footer.
/// Typically used for primary CTAs at the bottom of import flows and sheets.
///
/// Usage:
/// ```swift
/// ScrollView {
///     ImportTransactionListView(...)
/// }
/// .stickyFooter {
///     FDSLiquidButton("Import 42 Transactions", variant: .primary) { confirmImport() }
///         .frame(maxWidth: .infinity)
/// }
/// ```
/// ViewModifier that pins a footer below scrollable content. Use `.stickyFooter {}` convenience.
public struct StickyFooterModifier<Footer: View>: ViewModifier {
    /// The footer view rendered below the separator.
    let footer: Footer

    public func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content

            Divider()
                .opacity(0.15)

            footer
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
        }
    }
}

public extension View {
    func stickyFooter(@ViewBuilder content: () -> some View) -> some View {
        modifier(StickyFooterModifier(footer: content()))
    }
}
