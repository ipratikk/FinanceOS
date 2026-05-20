import SwiftUI

/// Wraps a view with standard snapshot testing infrastructure.
/// Applies deterministic environment, sizing, and device configuration.
public struct SnapshotContainer<Content: View>: View {
    let content: Content
    let device: SnapshotDevice
    let colorScheme: ColorScheme

    public var body: some View {
        content
            .snapshotEnvironment(colorScheme: colorScheme)
            .frame(width: device.size.width, height: device.size.height)
            .background(Color(white: 1))
            .clipped()
    }

    public init(
        _ content: Content,
        device: SnapshotDevice = .macDefault,
        colorScheme: ColorScheme = .light
    ) {
        self.content = content
        self.device = device
        self.colorScheme = colorScheme
    }
}

/// Wraps a component with standard sizing for snapshot testing.
public struct ComponentSnapshotContainer<Content: View>: View {
    let content: Content
    let size: CGSize
    let colorScheme: ColorScheme

    public var body: some View {
        content
            .snapshotEnvironment(colorScheme: colorScheme)
            .frame(width: size.width, height: size.height)
            .background(Color(white: 1))
            .clipped()
    }

    public init(
        _ content: Content,
        size: CGSize = CGSize(width: 390, height: 200),
        colorScheme: ColorScheme = .light
    ) {
        self.content = content
        self.size = size
        self.colorScheme = colorScheme
    }
}
