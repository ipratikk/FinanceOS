import FinanceCore
import SwiftUI

/// Image rendering with fallback sf symbol
///
/// Hierarchy:
/// 1. Logo image if available
/// 2. SF Symbol if category-known
///
public struct FDSImage: View {
    let imageName: String?
    let fallbackSymbol: String?
    let height: CGFloat
    let width: CGFloat

    public init(
        imageName: String? = nil,
        fallbackSymbol: String? = nil,
        height: CGFloat = 32,
        width: CGFloat = 32
    ) {
        self.imageName = imageName
        self.fallbackSymbol = fallbackSymbol
        self.height = height
        self.width = width
    }

    public var body: some View {
        Group {
            if let imageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
            } else if let symbol = fallbackSymbol, !symbol.isEmpty {
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            } else {
                // Ensure there's always some content so type inference succeeds
                Rectangle()
                    .fill(Color.clear)
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
}
