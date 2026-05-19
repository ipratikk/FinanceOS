import SwiftUI

/// 32×32 category icon glyph with hue-based background and foreground.
///
/// Background: HSB color with saturation 0.42, brightness 0.22.
/// Foreground: HSB color with saturation 0.55, brightness 0.78.
/// Used in transaction rows to identify spending category.
public struct FDSCategoryGlyph: View {
    let category: String
    let icon: String
    let size: CGFloat

    public init(_ category: String, icon: String, size: CGFloat = 32) {
        self.category = category
        self.icon = icon
        self.size = size
    }

    public var body: some View {
        let hue = categoryHue(for: category)
        let bgColor = Color(hue: hue / 360, saturation: 0.42, brightness: 0.22)
        let fgColor = Color(hue: hue / 360, saturation: 0.55, brightness: 0.78)

        ZStack {
            RoundedRectangle(cornerRadius: size * 0.31, style: .continuous)
                .fill(.regularMaterial)

            RoundedRectangle(cornerRadius: size * 0.31, style: .continuous)
                .fill(bgColor.opacity(0.6))

            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundColor(fgColor)

            RoundedRectangle(cornerRadius: size * 0.31, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.16),
                            Color.white.opacity(0.06),
                            .clear,
                            Color.black.opacity(0.20)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
    }

    private func categoryHue(for category: String) -> Double {
        let normalized = category.lowercased()

        let hueMap: [String: Double] = [
            "food": 22,
            "dining": 22,
            "groceries": 142,
            "transport": 200,
            "shopping": 312,
            "bills": 48,
            "travel": 178,
            "health": 0,
            "rent": 268,
            "entertainment": 332,
            "transfer": 220,
            "salary": 142,
            "income": 142,
            "fee": 12,
            "other": 220
        ]

        for (key, hue) in hueMap {
            if normalized.contains(key) {
                return hue
            }
        }

        return 220
    }
}

#Preview {
    HStack(spacing: 12) {
        FDSCategoryGlyph("food", icon: "fork.knife")
        FDSCategoryGlyph("groceries", icon: "cart.fill")
        FDSCategoryGlyph("transport", icon: "car.fill")
        FDSCategoryGlyph("shopping", icon: "bag.fill")
        FDSCategoryGlyph("bills", icon: "bolt.fill")
    }
    .padding()
}
