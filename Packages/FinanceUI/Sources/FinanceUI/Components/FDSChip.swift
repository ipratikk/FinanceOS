import SwiftUI

/// Filter chip with active/inactive states and color tones.
///
/// Inactive: glass pill with secondary text.
/// Active: accent tinted fill + accent text.
/// Tones: credit (green), debit (red), accent (orange).
public struct FDSChip: View {
    let label: String
    let isActive: Bool
    let tone: Tone
    let action: () -> Void

    @State private var isHovered = false

    public enum Tone {
        case credit, debit, accent
    }

    public init(
        _ label: String,
        isActive: Bool,
        tone: Tone = .accent,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.isActive = isActive
        self.tone = tone
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(foregroundColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background {
                    if isActive {
                        Capsule()
                            .fill(accentColor.opacity(0.18))
                            .overlay {
                                Capsule()
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
                    } else {
                        Capsule()
                            .fill(.regularMaterial)
                            .overlay {
                                Capsule()
                                    .fill(Color.white.opacity(0.06))
                            }
                            .overlay {
                                Capsule()
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
                    }
                }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isActive)
    }

    private var accentColor: Color {
        switch tone {
        case .credit:
            Color(red: 0.19, green: 0.82, blue: 0.35)
        case .debit:
            Color(red: 1.0, green: 0.27, blue: 0.23)
        case .accent:
            Color(red: 1.0, green: 0.62, blue: 0.04)
        }
    }

    private var foregroundColor: Color {
        if isActive {
            return accentColor
        } else {
            return Color(red: 0.741, green: 0.761, blue: 0.800)
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        FDSChip("All", isActive: true) {}
        FDSChip("Debits", isActive: false, tone: .debit) {}
        FDSChip("Credits", isActive: false, tone: .credit) {}
    }
    .padding()
}
