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
                // Wrap in ZStack with a fixed-size AppColors.clear background so SwiftUI
                // resolves the container size (width x height) first, then scales the
                // image to fit within that box. Without this, wide-aspect images like
                // the Amex logo (15:1) report a huge intrinsic width that Menu items
                // cannot override with downstream .frame() modifiers.
                ZStack {
                    AppColors.clear
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                }
                .frame(width: width, height: height)
                .clipped()
            } else if let symbol = fallbackSymbol, !symbol.isEmpty {
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                    .foregroundStyle(.secondary)
            } else {
                Rectangle()
                    .fill(AppColors.clear)
                    .frame(width: width, height: height)
            }
        }
        .frame(width: width, height: height)
    }
}
