import SwiftUI

/// Tracks live window size and exposes responsive percentage helpers.
/// Each view owns an instance via `@State`. All helpers recompute on window resize.
@Observable
final class WindowSizing {
    var liveWindowSize: CGSize = .zero

    init() {
        liveWindowSize = NSApp.keyWindow?.frame.size ?? .zero
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func windowDidResize() {
        liveWindowSize = NSApp.keyWindow?.frame.size ?? .zero
    }

    // MARK: - Reference

    var screenFrame: CGRect {
        NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }

    var referenceSize: CGSize {
        liveWindowSize != .zero ? liveWindowSize : screenFrame.size
    }

    // MARK: - Width helpers

    var sysWidth35: CGFloat {
        referenceSize.width * 0.35
    }

    var sysWidth40: CGFloat {
        referenceSize.width * 0.40
    }

    var sysWidth50: CGFloat {
        referenceSize.width * 0.50
    }

    var sysWidth70: CGFloat {
        referenceSize.width * 0.70
    }

    // MARK: - Height helpers

    var sysHeight60: CGFloat {
        referenceSize.height * 0.60
    }

    var sysHeight70: CGFloat {
        referenceSize.height * 0.70
    }

    var sysHeight80: CGFloat {
        referenceSize.height * 0.80
    }

    // MARK: - Clamped helpers

    func clampedWidth(fraction: CGFloat, min minVal: CGFloat = 0, max maxVal: CGFloat = .infinity) -> CGFloat {
        Swift.min(Swift.max(referenceSize.width * fraction, minVal), maxVal)
    }

    func clampedHeight(fraction: CGFloat, min minVal: CGFloat = 0, max maxVal: CGFloat = .infinity) -> CGFloat {
        Swift.min(Swift.max(referenceSize.height * fraction, minVal), maxVal)
    }
}

// MARK: - Window resizability accessor

private struct ResizableWindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { view.window?.styleMask.insert(.resizable) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.window?.styleMask.insert(.resizable)
    }
}

// MARK: - ViewModifier

struct ResponsiveFrameModifier: ViewModifier {
    let widthFraction: CGFloat
    let heightFraction: CGFloat
    let minWidth: CGFloat
    let maxWidth: CGFloat
    let minHeight: CGFloat
    let maxHeight: CGFloat

    @State private var sizing = WindowSizing()

    func body(content: Content) -> some View {
        content
            .frame(
                minWidth: minWidth,
                idealWidth: sizing.clampedWidth(fraction: widthFraction, min: minWidth, max: maxWidth),
                maxWidth: maxWidth,
                minHeight: minHeight,
                idealHeight: sizing.clampedHeight(fraction: heightFraction, min: minHeight, max: maxHeight),
                maxHeight: maxHeight
            )
            .background(ResizableWindowAccessor())
            .environment(sizing)
    }
}

extension View {
    func responsiveFrame(
        widthFraction: CGFloat = 0.7,
        heightFraction: CGFloat = 0.7,
        minWidth: CGFloat = 0,
        maxWidth: CGFloat = .infinity,
        minHeight: CGFloat = 0,
        maxHeight: CGFloat = .infinity
    ) -> some View {
        modifier(ResponsiveFrameModifier(
            widthFraction: widthFraction,
            heightFraction: heightFraction,
            minWidth: minWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            maxHeight: maxHeight
        ))
    }
}
