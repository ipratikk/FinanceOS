import FinanceCore
import FinanceUI
import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @State private var notifications = true
    @State private var autoRefresh = true
    @State private var showConfirmClear = false

    var onClearAll: (() async -> Void)?

    enum SettingsTab: CaseIterable {
        case general, about

        var label: String {
            switch self {
            case .general: "General"
            case .about: "About"
            }
        }

        var symbol: String {
            switch self {
            case .general: "gearshape"
            case .about: "info.circle"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            sideTabs

            Divider().opacity(0.3)

            ScrollView(showsIndicators: false) {
                Group {
                    if selectedTab == .general {
                        generalSettings
                    } else {
                        aboutSettings
                    }
                }
                .padding(AppSpacing.xl)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .background(AppColors.base)
        .alert("Clear All Data?", isPresented: $showConfirmClear) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                Task { await onClearAll?() }
            }
        } message: {
            Text("This will permanently delete all data including banks, accounts, cards, and transactions.")
        }
    }

    private var sideTabs: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Settings")
                    .font(AppTypography.headingMd)
                    .foregroundStyle(.primary)
                Text("Preferences")
                    .font(AppTypography.labelMedium)
                    .tracking(0.5)
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 1) {
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
        .padding(AppSpacing.xl)
        .frame(width: 220)
        .background(.regularMaterial)
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            sectionTitle("General")

            FDSGlassSurface(cornerRadius: AppRadius.lg) {
                VStack(spacing: 0) {
                    toggleRow("Notifications", symbol: "bell.fill", binding: $notifications)
                    Divider().opacity(0.3).padding(.vertical, AppSpacing.compact)
                    toggleRow("Auto-Refresh", symbol: "arrow.clockwise", binding: $autoRefresh)
                }
            }

            sectionTitle("Danger Zone")

            Button(action: { showConfirmClear = true }) {
                HStack(spacing: AppSpacing.compact) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(AppTypography.captionLgSemibold)
                    Text("Clear All Data")
                        .caption()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(AppTypography.labelSemibold)
                }
                .foregroundStyle(AppColors.danger)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .fill(AppColors.danger.opacity(0.12))
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var aboutSettings: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            sectionTitle("About")

            FDSGlassSurface(cornerRadius: AppRadius.lg) {
                VStack(spacing: 0) {
                    infoRow("Version", value: "1.0.0", copyable: true)
                    Divider().opacity(0.3).padding(.vertical, AppSpacing.compact)
                    infoRow("Build", value: "2026.05.16", copyable: true)
                    Divider().opacity(0.3).padding(.vertical, AppSpacing.compact)
                    infoRow("Platform", value: "macOS", copyable: false)
                }
            }

            sectionTitle("Links")

            FDSGlassSurface(cornerRadius: AppRadius.lg, padding: 0) {
                VStack(spacing: 0) {
                    linkRow("GitHub Repository", symbol: "link")
                    Divider().opacity(0.3)
                    linkRow("Report a Bug", symbol: "ladybug.fill")
                    Divider().opacity(0.3)
                    linkRow("Privacy Policy", symbol: "lock.fill")
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.headlineSmall)
            .foregroundStyle(.primary)
    }

    private func toggleRow(_ label: String, symbol: String, binding: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: symbol)
                .caption()
                .foregroundStyle(.secondary)
                .frame(width: 22)
            Text(label)
                .caption()
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }

    private func infoRow(_ label: String, value: String, copyable: Bool) -> some View {
        HStack {
            Text(label.uppercased())
                .font(AppTypography.labelSemibold)
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            Spacer()
            Text(value)
                .font(AppTypography.bodySmMedium.monospacedDigit())
            if copyable {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(AppTypography.captionSm)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func linkRow(_ label: String, symbol: String) -> some View {
        Button(action: {}) {
            HStack(spacing: AppSpacing.compact) {
                Image(systemName: symbol)
                    .labelSmall()
                    .foregroundStyle(AppColors.accentGold)
                    .frame(width: 22)
                Text(label)
                    .caption()
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(AppTypography.labelSemibold)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}
