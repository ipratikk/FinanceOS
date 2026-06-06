import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

struct FDSScaleModifier: ViewModifier {
    @State private var scale: FDSScale = .default

    func body(content: Content) -> some View {
        content
            .environment(\.fdsScale, scale)
            .onAppear { scale = resolvedScale() }
        #if os(macOS)
            .onReceive(
                NotificationCenter.default.publisher(
                    for: NSApplication.didChangeScreenParametersNotification
                )
            ) { _ in scale = resolvedScale() }
        #endif
    }

    private func resolvedScale() -> FDSScale {
        #if os(macOS)
        let width = NSScreen.main?.frame.width ?? 1280
        #else
        let width: CGFloat = 1280
        #endif
        let breakpoint = FDSBreakpoint(screenWidth: width)
        return FDSScale(
            typography: breakpoint.typographyScale,
            spacing: breakpoint.spacingScale,
            breakpoint: breakpoint
        )
    }
}

public extension View {
    func fdsAdaptive() -> some View {
        modifier(FDSScaleModifier())
    }
}
