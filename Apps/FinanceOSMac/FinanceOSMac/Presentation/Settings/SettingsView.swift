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
            Divider().opacity(DesignTokens.Opacity.low)
            ScrollView(showsIndicators: false) {
                Group {
                    if selectedTab == .general {
                        generalSettings
                    } else {
                        aboutSettings
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
                Task { await onClearAll?() }
            }
        } message: {
            Text("This will permanently delete all data including banks, accounts, cards, and transactions.")
        }
    }

    private var sideTabs: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(AppTypography.headingMd)
                    .foregroundColor(DesignTokens.Text.primary)
                Text("Preferences")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(DesignTokens.Text.tertiary)
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
                    Divider().opacity(DesignTokens.Opacity.low).padding(.vertical, 8)
                    toggleRow("Auto-Refresh", symbol: "arrow.clockwise", binding: $autoRefresh)
                }
                .padding(AppSpacing.sm)
            }

            sectionTitle("Danger Zone")

            Button(action: { showConfirmClear = true }, label: {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Clear All Data")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                }
            })
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(DesignTokens.System.red.opacity(0.18))
            .foregroundColor(DesignTokens.System.red)
            .cornerRadius(8)
            .buttonStyle(.plain)
        }
    }

    private var aboutSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("About")

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 0) {
                    infoRow("Version", value: "1.0.0", copyable: true)
                    Divider().opacity(DesignTokens.Opacity.low).padding(.vertical, 8)
                    infoRow("Build", value: "2026.05.16", copyable: true)
                    Divider().opacity(DesignTokens.Opacity.low).padding(.vertical, 8)
                    infoRow("Platform", value: "macOS", copyable: false)
                }
                .padding(AppSpacing.sm)
            }

            sectionTitle("Links")

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 0) {
                    linkRow("GitHub Repository", symbol: "link")
                    Divider().opacity(DesignTokens.Opacity.low)
                    linkRow("Report a Bug", symbol: "ladybug.fill")
                    Divider().opacity(DesignTokens.Opacity.low)
                    linkRow("Privacy Policy", symbol: "lock.fill")
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.bodyMdSemibold)
            .foregroundColor(DesignTokens.Text.primary)
    }

    private func toggleRow(_ label: String, symbol: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: symbol)
                .font(AppTypography.bodySmMedium)
                .foregroundColor(DesignTokens.Text.secondary)
                .frame(width: 22)
            Text(label)
                .font(AppTypography.bodySmMedium)
                .foregroundColor(DesignTokens.Text.primary)
            Spacer()
            FDSToggle(isOn: binding)
        }
    }

    private func infoRow(_ label: String, value: String, copyable: Bool) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(DesignTokens.Text.tertiary)
            Spacer()
            Text(value)
                .font(AppTypography.bodySmMedium)
                .foregroundColor(DesignTokens.Text.secondary)
            if copyable {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                }, label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignTokens.Text.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.sm)
    }

    private func linkRow(_ label: String, symbol: String) -> some View {
        Button(action: {}, label: {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignTokens.System.orange)
                    .frame(width: 22)
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignTokens.Text.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignTokens.Text.secondary)
            }
            .padding(12)
        })
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}
