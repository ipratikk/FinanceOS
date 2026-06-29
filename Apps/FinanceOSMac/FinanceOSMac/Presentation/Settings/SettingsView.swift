import FinanceCore
import FinanceUI
import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @State private var notifications = true
    @State private var autoRefresh = true
    @State private var showConfirmClear = false
    @State private var viewModel: SettingsViewModel
    @AppStorage("developerModeEnabled") private var developerModeEnabled = false

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

// Preview removed — inject SettingsViewModel from call site
