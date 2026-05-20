import FinanceCore
import SwiftUI

/// Filter chip with active/inactive states and color tones.
///
/// Inactive: dark pill with secondary text.
/// Active: accent tinted fill + accent text.
/// Tones: credit (green), debit (red), accent (green).
public struct FDSChip: View {
    let label: String
    let isActive: Bool
    let tone: Tone
    let isEnabled: Bool
    let action: () -> Void

    public enum Tone {
        case credit, debit, accent
    }

    public init(
        _ label: String,
        isActive: Bool,
        tone: Tone = .accent,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.isActive = isActive
        self.tone = tone
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action, label: {
            FDSLabel(label)
                .font(AppTypography.captionLgSemibold)
                .foregroundColor(foregroundColor)
                .padding(.horizontal, AppSpacing.sm)
                // 7pt design spec; AppSpacing.compact is 8pt (nearest token)
                .padding(.vertical, AppSpacing.compact)
                .background {
                    if isActive {
                        Capsule()
                            // chip tint — intentionally lighter than Opacity.low (0.20)
                            .fill(accentColor.opacity(0.18))
                            .overlay(
                                Capsule().strokeBorder(accentColor.opacity(AppColors.Opacity.muted), lineWidth: 0.5)
                            )
                    } else {
                        Capsule()
                            .fill(AppColors.surface2)
                            .overlay(Capsule().strokeBorder(AppColors.border, lineWidth: 0.5))
                    }
                }
        })
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : AppColors.Opacity.muted)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isActive)
        .accessibilityLabel("\(label)\(isActive ? ", selected" : "")")
    }

    private var accentColor: Color {
        switch tone {
        case .credit:
            AppColors.success
        case .debit:
            AppColors.danger
        case .accent:
            AppColors.accent
        }
    }

    private var foregroundColor: Color {
        if isActive {
            return accentColor
        } else {
            return AppColors.textSecondary
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
