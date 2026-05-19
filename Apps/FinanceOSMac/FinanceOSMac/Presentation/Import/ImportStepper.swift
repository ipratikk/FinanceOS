import FinanceCore
import FinanceUI
import SwiftUI

struct ImportStepper: View {
    let step: ImportViewModel.Step
    let onStartOver: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 12) {
                stepIndicator(1, label: "Source", isComplete: step.rawValue > 0, isCurrent: step == .source)
                stepRule(isComplete: step.rawValue > 0)
                stepIndicator(2, label: "Upload", isComplete: step.rawValue > 1, isCurrent: step == .upload)
                stepRule(isComplete: step.rawValue > 1)
                stepIndicator(3, label: "Review", isComplete: false, isCurrent: step == .review)
            }

            Spacer()

            Button(action: onStartOver) {
                Text("Start over")
                    .font(AppTypography.labelMedium)
            }
            .buttonStyle(.plain)
            .foregroundColor(AppColors.accent)
            .contentShape(Rectangle())
        }
        .padding(AppSpacing.lg)
        .background(DesignTokens.Background.surfaceGlass)
        .cornerRadius(AppRadius.md)
    }

    private func stepIndicator(
        _ number: Int,
        label: String,
        isComplete: Bool,
        isCurrent: Bool
    ) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        isCurrent
                            ? AppColors.accent
                            : (isComplete ? AppColors.success : AppColors.surface)
                    )
                    .frame(width: 28, height: 28)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isCurrent ? .black : DesignTokens.Text.tertiary)
                }
            }

            Text(label)
                .font(AppTypography.labelSmall)
                .foregroundColor(isCurrent ? AppColors.accent : DesignTokens.Text.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func stepRule(isComplete: Bool) -> some View {
        Rectangle()
            .fill(isComplete ? AppColors.success : DesignTokens.Border.subtle)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 16) {
        ImportStepper(step: .source, onStartOver: {})
        ImportStepper(step: .upload, onStartOver: {})
        ImportStepper(step: .review, onStartOver: {})
    }
    .padding()
}
