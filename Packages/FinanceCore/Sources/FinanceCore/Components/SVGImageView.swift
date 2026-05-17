import SwiftUI

public struct SVGImageView: View {
    let url: URL?
    let frameWidth: CGFloat?
    let frameHeight: CGFloat?

    public init(_ url: URL?, width: CGFloat? = nil, height: CGFloat? = nil) {
        self.url = url
        frameWidth = width
        frameHeight = height
    }

    public var body: some View {
        Group {
            if let url {
                if url.isFileURL, url.pathExtension == "svg" {
                    Image(nsImage: loadSVGImage(from: url))
                        .resizable()
                        .scaledToFit()
                        .frame(width: frameWidth, height: frameHeight)
                } else {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: frameWidth, height: frameHeight)
                        case .empty:
                            Color.gray.opacity(0.2)
                                .frame(width: frameWidth, height: frameHeight)
                        case .failure:
                            Color.gray.opacity(0.2)
                                .frame(width: frameWidth, height: frameHeight)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
        }
    }

    private func loadSVGImage(from url: URL) -> NSImage {
        // Try loading from file path
        let path = url.path
        if let nsImage = NSImage(byReferencingFile: path) {
            return nsImage
        }
        // Fallback: try contentsOf
        if let nsImage = NSImage(contentsOf: url) {
            return nsImage
        }
        return NSImage()
    }
}
