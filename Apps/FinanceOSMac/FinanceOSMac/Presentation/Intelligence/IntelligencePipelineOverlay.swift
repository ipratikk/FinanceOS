import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

// MARK: - Pipeline Stage

enum PipelineStage: Int, CaseIterable {
    case analyzing = 0
    case graph = 1
    case patterns = 2
    case relationships = 3

    var title: String {
        switch self {
        case .analyzing: return "Analyzing Transactions"
        case .graph: return "Building Knowledge Graph"
        case .patterns: return "Detecting Recurring Patterns"
        case .relationships: return "Inferring Relationships"
        }
    }

    var icon: String {
        switch self {
        case .analyzing: return "brain.head.profile"
        case .graph: return "point.3.connected.trianglepath.dotted"
        case .patterns: return "arrow.trianglehead.2.clockwise"
        case .relationships: return "person.2.fill"
        }
    }
}

// MARK: - Overlay

struct IntelligencePipelineOverlay: View {
    let processed: Int
    let total: Int
    let currentStage: PipelineStage
    let onCancel: () -> Void

    private var progress: Double {
        guard total > 0 else { return 0 }
        let stageBase = Double(currentStage.rawValue) / Double(PipelineStage.allCases.count)
        let stageProgress = Double(processed) / Double(max(total, 1)) / Double(PipelineStage.allCases.count)
        return min(stageBase + stageProgress, 1.0)
    }

    var body: some View {
        ZStack {
            AppColors.base.opacity(0.85)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)

            VStack(spacing: 0) {
                Spacer()
                panel
                Spacer()
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: currentStage)
    }

    private var panel: some View {
        VStack(spacing: AppSpacing.xl) {
            headerSection
            progressRing
            stageList
            cancelButton
        }
        .padding(AppSpacing.xxl)
        .frame(width: 420)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                        .strokeBorder(AppColors.border, lineWidth: 0.5)
                )
        }
        .shadow(color: .black.opacity(0.4), radius: 40, x: 0, y: 20)
    }

    private var headerSection: some View {
        VStack(spacing: AppSpacing.compact) {
            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColors.accent)
                .symbolEffect(.variableColor.iterative, isActive: true)

            FDSLabel("Intelligence Pipeline")
                .font(AppTypography.headingMd)
                .foregroundStyle(AppColors.textPrimary)

            FDSLabel(currentStage.title)
                .font(AppTypography.captionLg)
                .foregroundStyle(AppColors.textSecondary)
                .animation(.easeInOut, value: currentStage)
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(AppColors.surface2, lineWidth: 6)
                .frame(width: 88, height: 88)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppColors.accent,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 88, height: 88)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)

            VStack(spacing: 1) {
                FDSLabel("\(Int(progress * 100))%")
                    .font(AppTypography.headingSmall.monospacedDigit())
                    .foregroundStyle(AppColors.textPrimary)

                if total > 0, currentStage == .analyzing {
                    FDSLabel("\(processed)/\(total)")
                        .font(AppTypography.captionSm.monospacedDigit())
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    private var stageList: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.1)
            ForEach(PipelineStage.allCases, id: \.rawValue) { stage in
                stageRow(stage)
                if stage.rawValue < PipelineStage.allCases.count - 1 {
                    Divider().opacity(0.06).padding(.leading, 44)
                }
            }
            Divider().opacity(0.1)
        }
    }

    private func stageRow(_ stage: PipelineStage) -> some View {
        let isDone = stage.rawValue < currentStage.rawValue
        let isActive = stage == currentStage
        let isPending = stage.rawValue > currentStage.rawValue

        return HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(isDone ? AppColors.accent.opacity(0.15) :
                        isActive ? AppColors.accent.opacity(0.1) : AppColors.surface2)
                    .frame(width: 28, height: 28)

                if isDone {
                    Image(systemName: "checkmark")
                        .font(AppTypography.captionSmSemibold)
                        .foregroundStyle(AppColors.accent)
                } else {
                    Image(systemName: stage.icon)
                        .font(AppTypography.captionSm)
                        .foregroundStyle(isActive ? AppColors.accent : AppColors.textSecondary)
                }
            }

            FDSLabel(stage.title)
                .font(isActive ? AppTypography.captionLgSemibold : AppTypography.captionLg)
                .foregroundStyle(isPending ? AppColors.textSecondary.opacity(0.5) :
                    isDone ? AppColors.textSecondary : AppColors.textPrimary)

            Spacer()

            stageStatusBadge(isDone: isDone, isActive: isActive)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.compact)
    }

    private func stageStatusBadge(isDone: Bool, isActive: Bool) -> some View {
        Group {
            if isDone {
                FDSLabel("Done")
                    .font(AppTypography.captionSm)
                    .foregroundStyle(AppColors.accent)
            } else if isActive {
                HStack(spacing: 4) {
                    ProgressView().controlSize(.mini)
                    FDSLabel("Running")
                        .font(AppTypography.captionSm)
                        .foregroundStyle(AppColors.textSecondary)
                }
            } else {
                FDSLabel("Waiting")
                    .font(AppTypography.captionSm)
                    .foregroundStyle(AppColors.textSecondary.opacity(0.4))
            }
        }
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
            FDSLabel("Cancel")
                .font(AppTypography.captionLgMedium)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.compact)
                .background(AppColors.surface2)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
