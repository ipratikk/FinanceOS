import SwiftUI

/// Wraps a view with standard snapshot testing infrastructure.
/// Applies deterministic environment, sizing, and device configuration.
public struct SnapshotContainer<Content: View>: View {
    let content: Content
    let configuration: SnapshotConfiguration
    let device: SnapshotDevice
    let name: String?

    public var body: some View {
        content
            .snapshotEnvironment(configuration)
            .frame(width: device.size.width, height: device.size.height)
            .background(Color.white)
            .clipped()
    }

    public init(
        _ content: Content,
        configuration: SnapshotConfiguration = .default,
        device: SnapshotDevice = .iPhone16Pro,
        name: String? = nil
    ) {
        self.content = content
        self.configuration = configuration
        self.device = device
        self.name = name
    }
}

/// Wraps a component with standard sizing for snapshot testing.
public struct ComponentSnapshotContainer<Content: View>: View {
    let content: Content
    let configuration: SnapshotConfiguration
    let size: CGSize

    public var body: some View {
        content
            .snapshotEnvironment(configuration)
            .frame(width: size.width, height: size.height)
            .background(Color.white)
            .clipped()
    }

    public init(
        _ content: Content,
        configuration: SnapshotConfiguration = .default,
        size: CGSize = CGSize(width: 390, height: 200)
    ) {
        self.content = content
        self.configuration = configuration
        self.size = size
    }
}
