import SwiftUI

/// Transparent Text wrapper. Font and color are set by outer modifiers:
///
/// ```swift
/// FDSLabel("Overview")
///     .font(AppTypography.screenTitle)
///     .foregroundStyle(AppColors.Text.primary)
/// ```
public struct FDSLabel: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
    }
}
