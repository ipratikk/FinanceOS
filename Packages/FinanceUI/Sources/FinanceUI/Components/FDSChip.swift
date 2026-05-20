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
    let action: () -> Void

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
        Button(action: action, label: {
            FDSLabel(label)
                .font(AppTypography.custom(size: 12, weight: .semibold))
                .foregroundColor(foregroundColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background {
                    if isActive {
                        Capsule()
                            .fill(accentColor.opacity(0.18))
                            .overlay(Capsule().strokeBorder(accentColor.opacity(0.4), lineWidth: 0.5))
                    } else {
                        Capsule()
                            .fill(AppColors.surface2)
                            .overlay(Capsule().strokeBorder(AppColors.border, lineWidth: 0.5))
                    }
                }
        })
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isActive)
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
