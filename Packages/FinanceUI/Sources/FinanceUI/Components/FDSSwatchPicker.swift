import FinanceCore
import SwiftUI

/// 12-cell color swatch picker grid (1:1 aspect).
///
/// Selected swatch: 2.5pt accent ring outside. Used for bank color customization.
public struct FDSSwatchPicker: View {
    @Binding var selectedColor: Color
    /// Color options rendered in the grid. Defaults to `FDSSwatchPicker.defaultColors` (12 colors).
    let colors: [Color]

    public init(
        selectedColor: Binding<Color>,
        colors: [Color]? = nil
    ) {
        _selectedColor = selectedColor
        self.colors = colors ?? FDSSwatchPicker.defaultColors
    }

    /// 12-color default palette used when `colors` is not provided.
    public static let defaultColors: [Color] = [
        Color(red: 0.04, green: 0.52, blue: 1.00), // blue
        Color(red: 0.00, green: 0.00, blue: 0.40), // navy
        Color(red: 0.37, green: 0.36, blue: 0.90), // indigo
        Color(red: 0.75, green: 0.35, blue: 0.95), // purple
        Color(red: 1.00, green: 0.22, blue: 0.37), // pink
        Color(red: 1.00, green: 0.27, blue: 0.23), // red
        Color(red: 0.72, green: 0.00, blue: 0.00), // deep red
        Color(red: 1.00, green: 0.62, blue: 0.04), // orange
        Color(red: 0.19, green: 0.82, blue: 0.35), // green
        Color(red: 0.25, green: 0.78, blue: 0.88), // teal
        Color(red: 0.39, green: 0.82, blue: 1.00), // cyan
        Color(red: 0.60, green: 0.60, blue: 0.62) // gray
    ]

    private let colorNames = [
        "Blue", "Navy", "Indigo", "Purple", "Pink", "Red",
        "Deep Red", "Orange", "Green", "Teal", "Cyan", "Gray"
    ]

    public var body: some View {
        let gridItems = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

        LazyVGrid(columns: gridItems, spacing: 12) {
            ForEach(colors.indices, id: \.self) { index in
                let color = colors[index]
                let colorName = index < colorNames.count ? colorNames[index] : "Color \(index + 1)"
                let isSelected = selectedColor == color

                Button(action: { selectedColor = color }, label: {
                    Circle()
                        .fill(color)
                        .frame(height: 40)
                        .contentShape(Circle())
                        .overlay {
                            if isSelected {
                                Circle()
                                    .strokeBorder(AppColors.accent, lineWidth: 2.5)
                            }
                        }
                })
                .buttonStyle(.plain)
                .accessibilityLabel("Color option: \(colorName)")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

#Preview {
    FDSSwatchPicker(selectedColor: .constant(.blue))
        .padding()
}
