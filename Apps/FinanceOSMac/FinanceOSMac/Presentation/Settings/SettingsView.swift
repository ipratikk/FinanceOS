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
            Divider().opacity(0.2)
            ScrollView(showsIndicators: false) {
                Group {
                    if selectedTab == .general {
                        generalSettings
                    } else {
                        aboutSettings
                    }
                }
                .padding(16)
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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                Text("Preferences")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(Color(red: 0.518, green: 0.541, blue: 0.580))
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
        .padding(16)
        .frame(width: 220)
        .background(.regularMaterial)
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("General")

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 0) {
                    toggleRow("Notifications", symbol: "bell.fill", binding: $notifications)
                    Divider().opacity(0.2).padding(.vertical, 8)
                    toggleRow("Auto-Refresh", symbol: "arrow.clockwise", binding: $autoRefresh)
                }
                .padding(12)
            }

            sectionTitle("Danger Zone")

            Button(action: { showConfirmClear = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Clear All Data")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(red: 1.0, green: 0.27, blue: 0.23).opacity(0.18))
            .foregroundColor(Color(red: 1.0, green: 0.27, blue: 0.23))
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
                    Divider().opacity(0.2).padding(.vertical, 8)
                    infoRow("Build", value: "2026.05.16", copyable: true)
                    Divider().opacity(0.2).padding(.vertical, 8)
                    infoRow("Platform", value: "macOS", copyable: false)
                }
                .padding(12)
            }

            sectionTitle("Links")

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 0) {
                    linkRow("GitHub Repository", symbol: "link")
                    Divider().opacity(0.2)
                    linkRow("Report a Bug", symbol: "ladybug.fill")
                    Divider().opacity(0.2)
                    linkRow("Privacy Policy", symbol: "lock.fill")
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
    }

    private func toggleRow(_ label: String, symbol: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                .frame(width: 22)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
            Spacer()
            FDSToggle(isOn: binding)
        }
    }

    private func infoRow(_ label: String, value: String, copyable: Bool) -> some View {
        HStack(spacing: 12) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(Color(red: 0.518, green: 0.541, blue: 0.580))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            if copyable {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
    }

    private func linkRow(_ label: String, symbol: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.62, blue: 0.04))
                    .frame(width: 22)
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            }
            .padding(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}
