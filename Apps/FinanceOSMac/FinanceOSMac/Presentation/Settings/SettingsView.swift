import FinanceCore
import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @State private var darkMode = true
    @State private var showNotifications = true
    @State private var autoRefresh = true
    @State private var showConfirmClear = false

    enum SettingsTab {
        case general
        case about
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    settingTabButton("General", icon: "gear", tab: .general)
                    settingTabButton("About", icon: "info.circle", tab: .about)
                    Spacer()
                }
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .frame(width: 180)

                Divider()

                ScrollView {
                    Group {
                        if selectedTab == .general {
                            generalSettings
                        } else {
                            aboutSettings
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
        }
        .background(AppColors.base)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .headingLarge()

            Text("App preferences & information")
                .labelSmall()
        }
        .padding(AppSpacing.md)
        .background(AppColors.base)
        .border(AppColors.surface2, width: 1)
    }

    private func settingTabButton(_ label: String, icon: String, tab: SettingsTab) -> some View {
        Button(action: { selectedTab = tab }, label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .monoAmount()
                    .frame(width: 20)

                Text(label)
                    .captionLarge()

                Spacer()
            }
            .foregroundColor(selectedTab == tab ? .white : Color(
                red: 0.447, green: 0.447, blue: 0.478
            ))
            .padding(AppSpacing.xs)
            .background(selectedTab == tab ? AppColors.accent
                .opacity(0.2) : Color.clear)
            .cornerRadius(AppRadius.sm)
        })
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsSection("Display", items: [
                ("Dark Mode", $darkMode, optional: false),
                ("Notifications", $showNotifications, optional: false),
                ("Auto-Refresh", $autoRefresh, optional: false)
            ])

            settingsSection("Data", items: [])

            VStack(alignment: .leading, spacing: 8) {
                Text("Danger Zone")
                    .captionLarge()
                    .foregroundColor(.gray)

                Button(
                    action: { showConfirmClear = true },
                    label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .labelSmall()

                            Text("Clear All Data")
                                .captionLarge()

                            Spacer()
                        }
                    }
                )
                .foregroundColor(.red)
                .padding(AppSpacing.sm)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(AppRadius.md)
            }
            .padding(AppSpacing.sm)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)

            Spacer()
        }
    }

    private var aboutSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            aboutItem("Version", value: "1.0.0")
            aboutItem("Build", value: "2026.05.16")
            aboutItem("Platform", value: "macOS")

            VStack(alignment: .leading, spacing: 8) {
                Text("Links")
                    .captionLarge()
                    .foregroundColor(.gray)

                VStack(spacing: 8) {
                    aboutLink("GitHub Repository", icon: "link")
                    aboutLink("Report a Bug", icon: "ladybug.fill")
                    aboutLink("Privacy Policy", icon: "lock.fill")
                }
            }
            .padding(AppSpacing.sm)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)

            Spacer()
        }
    }

    private func settingsSection(
        _ title: String,
        items: [(String, Binding<Bool>, optional: Bool)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .captionLarge()
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                ForEach(items.indices, id: \.self) { index in
                    let (label, binding, _) = items[index]
                    Toggle(label, isOn: binding)
                        .caption()
                        .padding(AppSpacing.xs)
                        .background(AppColors.surface2)
                        .cornerRadius(AppRadius.sm)
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }

    private func aboutItem(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .captionLarge()
                .foregroundColor(.gray)

            HStack {
                Text(value)
                    .caption()

                Spacer()

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                }, label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.accent)
                })
            }
            .padding(AppSpacing.xs)
            .background(AppColors.surface2)
            .cornerRadius(AppRadius.sm)
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }

    private func aboutLink(_ label: String, icon: String) -> some View {
        Button(action: {}, label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .labelSmall()

                Text(label)
                    .caption()

                Spacer()

                Image(systemName: "arrow.up.right")
                    .labelSmall()
            }
            .foregroundColor(AppColors.accent)
            .padding(AppSpacing.xs)
            .background(AppColors.surface2)
            .cornerRadius(AppRadius.sm)
        })
    }
}

#Preview {
    SettingsView()
}
