import FinanceCore
import SwiftUI

public enum FDSLabelStyle {
    case heading
    case subheading
    case caption
    case hint
}

public struct FDSLabel: View {
    let text: String
    let style: FDSLabelStyle

    public var body: some View {
        Text(text)
            .applyLabelStyle(style)
    }

    public init(_ text: String, style: FDSLabelStyle = .caption) {
        self.text = text
        self.style = style
    }
}

private extension View {
    func applyLabelStyle(_ style: FDSLabelStyle) -> some View {
        switch style {
        case .heading:
            return AnyView(font(.system(size: 16, weight: .semibold)).lineSpacing(1))
        case .subheading:
            return AnyView(font(.system(size: 12, weight: .regular)).lineSpacing(0))
        case .caption:
            return AnyView(font(.system(size: 10, weight: .regular)).lineSpacing(0))
        case .hint:
            return AnyView(font(.system(size: 12, weight: .medium)).lineSpacing(0))
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        FDSLabel("Section Header", style: .heading)
        FDSLabel("Subsection", style: .subheading)
        FDSLabel("Additional info", style: .caption)
        FDSLabel("Hint text", style: .hint)
    }
    .padding()
}
