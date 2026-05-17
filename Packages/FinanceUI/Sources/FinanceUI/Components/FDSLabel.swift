import FinanceCore
import SwiftUI

enum FDSLabelStyle {
    case heading
    case subheading
    case caption
    case hint
}

struct FDSLabel: View {
    let text: String
    let style: FDSLabelStyle

    var body: some View {
        Text(text)
            .applyLabelStyle(style)
    }

    init(_ text: String, style: FDSLabelStyle = .caption) {
        self.text = text
        self.style = style
    }
}

private extension View {
    func applyLabelStyle(_ style: FDSLabelStyle) -> some View {
        switch style {
        case .heading:
            return AnyView(self.headingSmall())
        case .subheading:
            return AnyView(self.captionLarge())
        case .caption:
            return AnyView(self.caption())
        case .hint:
            return AnyView(self.labelSmall())
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
