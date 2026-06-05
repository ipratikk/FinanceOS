import SwiftUI

struct FDSFontModifier: ViewModifier {
    let style: AppTypography.Style
    @Environment(\.fdsScale) private var fdsScale

    func body(content: Content) -> some View {
        content.font(style.font(scale: fdsScale.typography))
    }
}

public extension View {
    func fdsFont(_ style: AppTypography.Style) -> some View {
        modifier(FDSFontModifier(style: style))
    }
}
