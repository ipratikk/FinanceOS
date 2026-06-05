import SwiftUI

struct FDSPaddingModifier: ViewModifier {
    let edges: Edge.Set
    let base: CGFloat
    @Environment(\.fdsScale) private var fdsScale

    func body(content: Content) -> some View {
        content.padding(edges, base * fdsScale.spacing)
    }
}

public extension View {
    func fdsPadding(_ edges: Edge.Set = .all, _ base: CGFloat) -> some View {
        modifier(FDSPaddingModifier(edges: edges, base: base))
    }
}

public extension AppSpacing {
    static func scaled(_ base: CGFloat, by factor: CGFloat) -> CGFloat {
        base * factor
    }
}
