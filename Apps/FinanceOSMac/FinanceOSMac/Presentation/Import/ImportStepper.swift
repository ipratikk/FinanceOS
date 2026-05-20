import FinanceCore
import FinanceUI
import SwiftUI

struct ImportStepper: View {
    let step: ImportViewModel.Step
    let onStepSelect: (ImportViewModel.Step) -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text("Import Statements")
                .font(AppTypography.headingXL)
                .foregroundColor(DesignTokens.Text.primary)

            Spacer()

            HStack(spacing: 8) {
                stepButton(
                    1,
                    label: "Source",
                    isComplete: step.rawValue > 0,
                    isCurrent: step == .source,
                    target: .source
                )
                stepRule(isComplete: step.rawValue > 0)
                stepButton(
                    2,
                    label: "Upload",
                    isComplete: step.rawValue > 1,
                    isCurrent: step == .upload,
                    target: .upload
                )
                stepRule(isComplete: step.rawValue > 1)
                stepButton(3, label: "Review", isComplete: false, isCurrent: step == .review, target: .review)
            }
            .frame(maxWidth: 280)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }

    private func stepButton(
        _ number: Int,
        label: String,
        isComplete: Bool,
        isCurrent: Bool,
        target: ImportViewModel.Step
    ) -> some View {
        Button(action: { onStepSelect(target) }, label: {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(
                            isCurrent
                                ? AppColors.accent
                                : (isComplete ? AppColors.success : AppColors.surface)
                        )
                        .frame(width: 20, height: 20)

                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(number)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(isCurrent ? .black : DesignTokens.Text.tertiary)
                    }
                }

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isCurrent ? AppColors.accent : DesignTokens.Text.secondary)
            }
            .frame(maxWidth: .infinity)
        })
        .buttonStyle(.plain)
        .contentShape(Rectangle())
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
        ImportStepper(step: .source, onStepSelect: { _ in })
        ImportStepper(step: .upload, onStepSelect: { _ in })
        ImportStepper(step: .review, onStepSelect: { _ in })
    }
    .padding()
}
