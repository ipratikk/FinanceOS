import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @State private var notifications = true
    @State private var autoRefresh = true
    @State private var showConfirmClear = false
    @State private var viewModel: SettingsViewModel
    @State private var feedbackViewModel = FeedbackExportViewModel()
    @AppStorage("developerModeEnabled") private var developerModeEnabled = false
    @State private var modelDownloadState: ModelDownloadState = .notDownloaded
    @State private var isEmbeddingReady: Bool?
    @Environment(\.transactionIntelligence) private var intelligence

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    enum SettingsTab: CaseIterable {
        case general, developer, about

        var label: String {
            switch self {
            case .general: "General"
            case .developer: "Developer"
            case .about: "About"
            }
        }

        var symbol: String {
            switch self {
            case .general: "gearshape"
            case .developer: "hammer.fill"
            case .about: "info.circle"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            sideTabs
            Divider().opacity(AppColors.Opacity.low)
            ScrollView(showsIndicators: false) {
                Group {
                    switch selectedTab {
                    case .general: generalSettings
                    case .developer: developerSettings
                    case .about: aboutSettings
                    }
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .background(AppColors.base)
        .alert("Clear All Data?", isPresented: $showConfirmClear) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                Task { await viewModel.clearAllData() }
            }
        } message: {
            FDSLabel("This will permanently delete all data including banks, accounts, cards, and transactions.")
        }
        .task {
            for await state in await ModelDownloadManager.shared.stateStream() {
                modelDownloadState = state
            }
        }
        .task {
            // isEmbeddingModelReady reflects app-start state; requires app restart after model download.
            guard let svc = intelligence else { return }
            isEmbeddingReady = await svc.isEmbeddingModelReady
        }
        .task {
            await feedbackViewModel.load()
        }
    }

    private var sideTabs: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                FDSLabel("Settings")
                    .font(AppTypography.headingMd)
                    .foregroundColor(AppColors.Text.primary)
                FDSLabel("Preferences")
                    .font(AppTypography.captionSmSemibold)
                    .tracking(0.5)
                    .foregroundColor(AppColors.Text.tertiary)
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    FDSSidebarItem(
                        tab.label,
                        symbol: tab.symbol,
                        isSelected: selectedTab == tab,
                        action: { selectedTab = tab }
                    )
                }
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .frame(width: 220)
        .background(.regularMaterial)
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("General")

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 0) {
                    toggleRow("Notifications", symbol: "bell.fill", binding: $notifications)
                    Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                    toggleRow("Auto-Refresh", symbol: "arrow.clockwise", binding: $autoRefresh)
                }
                .padding(AppSpacing.sm)
            }

            modelDownloadSection
            FeedbackExportView(viewModel: feedbackViewModel)
            sectionTitle("Danger Zone")

            Button(action: { showConfirmClear = true }, label: {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(AppTypography.bodySmSemibold)
                    FDSLabel("Clear All Data")
                        .font(AppTypography.bodySmSemibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(AppTypography.bodySmSemibold)
                }
            })
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppColors.System.red.opacity(0.18))
            .foregroundColor(AppColors.System.red)
            .cornerRadius(8)
            .buttonStyle(.plain)
        }
    }

    private var developerSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("Developer")

            FDSCard(cornerRadius: 12, padded: false) {
                toggleRow("Developer Mode", symbol: "hammer.fill", binding: $developerModeEnabled)
                    .padding(AppSpacing.sm)
            }

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(alignment: .leading, spacing: AppSpacing.compact) {
                    FDSLabel("Enables the Financial Intelligence section in the sidebar.")
                        .font(AppTypography.captionLg)
                        .foregroundStyle(AppColors.Text.secondary)
                    FDSLabel(
                        "Provides CRUD access to persons, relationships, recurring patterns, and the knowledge graph."
                    )
                    .font(AppTypography.captionLg)
                    .foregroundStyle(AppColors.Text.secondary)
                }
                .padding(AppSpacing.sm)
            }
        }
    }

    private var aboutSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("About")

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 0) {
                    infoRow("Version", value: "1.0.0", copyable: true)
                    Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                    infoRow("Build", value: "2026.05.16", copyable: true)
                    Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                    infoRow("Platform", value: "macOS", copyable: false)
                }
                .padding(AppSpacing.sm)
            }

            sectionTitle("Links")

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 0) {
                    linkRow("GitHub Repository", symbol: "link")
                    Divider().opacity(AppColors.Opacity.low)
                    linkRow("Report a Bug", symbol: "ladybug.fill")
                    Divider().opacity(AppColors.Opacity.low)
                    linkRow("Privacy Policy", symbol: "lock.fill")
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        FDSLabel(title)
            .font(AppTypography.bodyMdSemibold)
            .foregroundColor(AppColors.Text.primary)
    }

    private func toggleRow(_ label: String, symbol: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: symbol)
                .font(AppTypography.bodySmMedium)
                .foregroundColor(AppColors.Text.secondary)
                .frame(width: 22)
            FDSLabel(label)
                .font(AppTypography.bodySmMedium)
                .foregroundColor(AppColors.Text.primary)
            Spacer()
            FDSToggle(isOn: binding)
        }
    }

    private func infoRow(_ label: String, value: String, copyable: Bool) -> some View {
        HStack(spacing: AppSpacing.sm) {
            FDSLabel(label.uppercased())
                .font(AppTypography.captionSmSemibold)
                .tracking(0.5)
                .foregroundColor(AppColors.Text.tertiary)
            Spacer()
            FDSLabel(value)
                .font(AppTypography.bodySmMedium)
                .foregroundColor(AppColors.Text.secondary)
            if copyable {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                }, label: {
                    Image(systemName: "doc.on.doc")
                        .font(AppTypography.captionSmMedium)
                        .foregroundColor(AppColors.Text.secondary)
                })
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.sm)
    }

    private func linkRow(_ label: String, symbol: String) -> some View {
        Button(action: {}, label: {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(AppTypography.bodySmMedium)
                    .foregroundColor(AppColors.System.orange)
                    .frame(width: 22)
                FDSLabel(label)
                    .font(AppTypography.bodySmMedium)
                    .foregroundColor(AppColors.Text.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(AppTypography.bodySmMedium)
                    .foregroundColor(AppColors.Text.secondary)
            }
            .padding(AppSpacing.xs)
        })
        .buttonStyle(.plain)
    }
}

// MARK: - AI Personalization

private extension SettingsView {
    var modelDownloadSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("AI Personalization")
            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 0) {
                    HStack(spacing: AppSpacing.compact) {
                        Image(systemName: "brain.head.profile")
                            .font(AppTypography.bodySmMedium)
                            .foregroundColor(AppColors.accentPurple)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            FDSLabel("NarrationEmbedder v0.1")
                                .font(AppTypography.bodySmSemibold)
                                .foregroundColor(AppColors.Text.primary)
                            FDSLabel("411 MB · Wi-Fi recommended")
                                .font(AppTypography.captionLg)
                                .foregroundColor(AppColors.Text.tertiary)
                        }
                        Spacer()
                        modelStatusBadge
                    }
                    modelDownloadActionContent
                    Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                    personalizationStatusRow
                }
                .padding(AppSpacing.sm)
            }
        }
    }

    var modelStatusBadge: some View {
        statusBadgeView(for: modelDownloadState)
    }

    var personalizationStatusRow: some View {
        let (label, color, symbol): (String, Color, String) = switch isEmbeddingReady {
        case .some(true): ("Personalization: Active", AppColors.success, "checkmark.circle.fill")
        case .some(false): (
                "Personalization: Download model to activate",
                AppColors.Text.secondary,
                "exclamationmark.circle"
            )
        case .none: ("Personalization: Initializing...", AppColors.Text.tertiary, "ellipsis.circle")
        }
        return HStack(spacing: AppSpacing.compact) {
            Image(systemName: symbol)
                .font(AppTypography.captionLg)
                .foregroundStyle(color)
            FDSLabel(label)
                .font(AppTypography.captionLg)
                .foregroundStyle(color)
        }
        .padding(.horizontal, AppSpacing.xs)
    }

    func statusBadgeView(for state: ModelDownloadState) -> some View {
        let (label, color): (String, Color) = {
            switch state {
            case .notDownloaded: return ("Not Downloaded", AppColors.Text.tertiary)
            case .downloading: return ("Downloading", AppColors.info)
            case .ready: return ("Ready", AppColors.success)
            case .failed: return ("Failed", AppColors.danger)
            }
        }()
        return FDSLabel(label)
            .font(AppTypography.captionSmSemibold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    @ViewBuilder
    var modelDownloadActionContent: some View {
        switch modelDownloadState {
        case .notDownloaded:
            Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
            modelActionButton(label: "Download Model", symbol: "arrow.down.circle.fill", tint: AppColors.accent)
        case let .downloading(progress):
            Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    FDSLabel(progress < 0.9 ? "Downloading…" : "Installing…")
                        .font(AppTypography.captionLg)
                        .foregroundColor(AppColors.Text.secondary)
                    Spacer()
                    FDSLabel("\(Int(progress * 100))%")
                        .font(AppTypography.captionLg)
                        .foregroundColor(AppColors.Text.tertiary)
                }
                ProgressView(value: progress, total: 1.0)
                    .tint(AppColors.accent)
            }
        case let .failed(message):
            Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
            VStack(alignment: .leading, spacing: 8) {
                FDSBanner(message, style: .error)
                modelActionButton(label: "Retry Download", symbol: "arrow.clockwise", tint: AppColors.danger)
            }
        case .ready:
            EmptyView()
        }
    }

    func modelActionButton(label: String, symbol: String, tint: Color) -> some View {
        Button(action: { Task { await ModelDownloadManager.shared.download() } }, label: {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(AppTypography.bodySmSemibold)
                FDSLabel(label)
                    .font(AppTypography.bodySmSemibold)
                Spacer()
            }
        })
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tint.opacity(0.18))
        .foregroundColor(tint)
        .cornerRadius(8)
        .buttonStyle(.plain)
    }
}

// Preview removed — inject SettingsViewModel from call site
