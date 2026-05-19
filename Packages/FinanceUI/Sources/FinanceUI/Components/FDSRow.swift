import FinanceCore
import SwiftUI

/// Structural row component for the Finance Design System.
///
/// Owns: spacing, alignment, flexible content compression, full-width hit target.
/// Leading and trailing slots are fixed-size; content slot expands to fill available space.
///
/// Usage:
/// ```swift
/// FDSRow {
///     FDSMerchantAvatar(...)
/// } content: {
///     VStack(alignment: .leading) {
///         Text(title).caption()
///         Text(subtitle).font(...)
///     }
/// } trailing: {
///     HStack { iconButton("pencil"), iconButton("trash") }
/// }
/// ```
public struct FDSRow<Leading: View, Content: View, Trailing: View>: View {
    private let leading: Leading
    private let content: Content
    private let trailing: Trailing

    public init(
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.leading = leading()
        self.content = content()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            leading
            content
                .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.lg)
        .contentShape(Rectangle())
    }
}
