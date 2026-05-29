import FinanceCore
import SwiftUI

/// A single step in a coach tip sequence.
public struct FDSCoachTipStep {
    /// Bold headline shown at top of the tip card.
    public let title: String
    /// Descriptive body text; wraps across multiple lines (fixed-size vertical).
    public let description: String

    public init(_ title: String, _ description: String) {
        self.title = title
        self.description = description
    }
}

/// Multi-step coach tip overlay for onboarding guidance.
///
/// Presented as a popover anchored to a view. Supports single or multi-step flows.
/// Navigation dots and Next/Got it controls are built-in.
///
/// Usage:
/// ```swift
/// ImportButton()
///     .coachTip(
///         steps: [
///             FDSCoachTipStep("Import a statement", "Tap here to import a CSV or PDF."),
///             FDSCoachTipStep("Review before saving", "Check parsed rows before confirming.")
///         ],
///         currentStep: $step,
///         isPresented: $showTip
///     )
/// ```
public struct FDSCoachTip: View {
    let steps: [FDSCoachTipStep]
    @Binding var currentStep: Int
    @Binding var isPresented: Bool

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if steps.count > 1 {
                stepIndicator
            }

            FDSLabel(steps[currentStep].title)
                .font(AppTypography.bodySmSemibold)
                .foregroundStyle(AppColors.Text.primary)

            FDSLabel(steps[currentStep].description)
                .font(AppTypography.captionSm)
                .foregroundStyle(AppColors.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                navigationButton
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: 260)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.surface2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(AppColors.Border.subtle, lineWidth: 1)
        }
        .shadow(color: AppColors.base.opacity(0.3), radius: 12, y: 4)
    }

    private var stepIndicator: some View {
        HStack(spacing: AppSpacing.tight) {
            ForEach(steps.indices, id: \.self) { i in
                Circle()
                    .fill(i == currentStep ? AppColors.accent : AppColors.Text.quaternary)
                    .frame(width: 5, height: 5)
                    .animation(AppAnimation.selection, value: currentStep)
            }
            Spacer()
            FDSLabel("\(currentStep + 1) of \(steps.count)")
                .font(AppTypography.captionSmSemibold)
                .foregroundStyle(AppColors.Text.tertiary)
        }
    }

    @ViewBuilder
    private var navigationButton: some View {
        if currentStep < steps.count - 1 {
            Button("Next") {
                withAnimation(AppAnimation.springSnappy) { currentStep += 1 }
            }
            .buttonStyle(.plain)
            .font(AppTypography.captionLgSemibold)
            .foregroundStyle(AppColors.accent)
        } else {
            Button("Got it") {
                withAnimation(AppAnimation.easeFast) { isPresented = false }
            }
            .buttonStyle(.plain)
            .font(AppTypography.captionLgSemibold)
            .foregroundStyle(AppColors.accent)
        }
    }
}

// MARK: - View Modifier

public extension View {
    /// Attach a coach tip popover to this view.
    ///
    /// - Parameters:
    ///   - steps: Ordered array of tip steps.
    ///   - currentStep: Binding to the active step index.
    ///   - isPresented: Controls presentation.
    ///   - arrowEdge: Which edge the popover arrow points from (default `.bottom`).
    func coachTip(
        steps: [FDSCoachTipStep],
        currentStep: Binding<Int>,
        isPresented: Binding<Bool>,
        arrowEdge: Edge = .bottom
    ) -> some View {
        popover(isPresented: isPresented, arrowEdge: arrowEdge) {
            FDSCoachTip(steps: steps, currentStep: currentStep, isPresented: isPresented)
                .background(AppColors.surface2)
        }
    }
}

#Preview {
    @Previewable @State var step = 0
    @Previewable @State var shown = true

    return ZStack {
        AppColors.base.ignoresSafeArea()

        Button("Import Statement") {}
            .buttonStyle(.plain)
            .font(AppTypography.bodyMdSemibold)
            .foregroundStyle(AppColors.accent)
            .coachTip(
                steps: [
                    FDSCoachTipStep("Import a statement", "Tap here to import a CSV or PDF."),
                    FDSCoachTipStep("Review before saving", "Check parsed rows, then confirm.")
                ],
                currentStep: $step,
                isPresented: $shown
            )
    }
}
