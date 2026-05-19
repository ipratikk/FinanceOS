import SwiftUI

/// Liquid Glass sidebar navigation item.
///
/// Active state: glass surface with gleam, accent icon.
/// Hover state: subtle white fill with gleam highlight.
/// Default: secondary text, no fill.
public struct FDSSidebarItem: View {
    let title: String
    let symbol: String
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    @State private var isHovered = false

    public init(
        _ title: String,
        symbol: String,
        isSelected: Bool,
        badge: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.symbol = symbol
        self.isSelected = isSelected
        self.badge = badge
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(
                        isSelected
                            ? Color(red: 1.0, green: 0.62, blue: 0.04)
                            : Color(red: 0.741, green: 0.761, blue: 0.800)
                    )
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 18)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(
                        isSelected || isHovered
                            ? Color(red: 0.945, green: 0.953, blue: 0.965)
                            : Color(red: 0.741, green: 0.761, blue: 0.800)
                    )

                Spacer(minLength: 4)

                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundColor(Color(red: 0.518, green: 0.541, blue: 0.580))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(.regularMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.white.opacity(0.10))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.16),
                                            Color.white.opacity(0.06),
                                            .clear,
                                            Color.black.opacity(0.20),
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        }
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.16),
                                            Color.white.opacity(0.06),
                                            .clear,
                                            Color.black.opacity(0.20),
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isSelected)
    }
}

/// Sidebar section header — uppercase, tracked, quaternary text.
public struct FDSSidebarSectionHeader: View {
    let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10.5, weight: .semibold))
            .tracking(0.08)
            .foregroundColor(Color(red: 0.333, green: 0.353, blue: 0.392))
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
