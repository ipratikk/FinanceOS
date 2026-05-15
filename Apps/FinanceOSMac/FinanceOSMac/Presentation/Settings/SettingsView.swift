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
                .padding(16)
                .background(Color(red: 0.086, green: 0.086, blue: 0.098))
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
                    .padding(16)
                }
            }
        }
        .background(Color(red: 0.051, green: 0.051, blue: 0.059))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .font(.system(size: 22, weight: .semibold))

            Text("App preferences & information")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
        }
        .padding(16)
        .background(Color(red: 0.051, green: 0.051, blue: 0.059))
        .border(Color(red: 0.110, green: 0.110, blue: 0.122), width: 1)
    }

    private func settingTabButton(_ label: String, icon: String, tab: SettingsTab) -> some View {
        Button(action: { selectedTab = tab }, label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 20)

                Text(label)
                    .font(.system(size: 13, weight: .medium))

                Spacer()
            }
            .foregroundColor(selectedTab == tab ? .white : Color(
                red: 0.447, green: 0.447, blue: 0.478
            ))
            .padding(10)
            .background(selectedTab == tab ? Color(red: 0.231, green: 0.510, blue: 0.980)
                .opacity(0.2) : Color.clear)
            .cornerRadius(6)
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)

                Button(
                    action: { showConfirmClear = true },
                    label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))

                            Text("Clear All Data")
                                .font(.system(size: 13, weight: .medium))

                            Spacer()
                        }
                    }
                )
                .foregroundColor(.red)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(12)
            .background(Color(red: 0.086, green: 0.086, blue: 0.098))
            .cornerRadius(10)

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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)

                VStack(spacing: 8) {
                    aboutLink("GitHub Repository", icon: "link")
                    aboutLink("Report a Bug", icon: "ladybug.fill")
                    aboutLink("Privacy Policy", icon: "lock.fill")
                }
            }
            .padding(12)
            .background(Color(red: 0.086, green: 0.086, blue: 0.098))
            .cornerRadius(10)

            Spacer()
        }
    }

    private func settingsSection(
        _ title: String,
        items: [(String, Binding<Bool>, optional: Bool)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                ForEach(items.indices, id: \.self) { index in
                    let (label, binding, _) = items[index]
                    Toggle(label, isOn: binding)
                        .font(.system(size: 13, weight: .regular))
                        .padding(10)
                        .background(Color(red: 0.110, green: 0.110, blue: 0.122))
                        .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .cornerRadius(10)
    }

    private func aboutItem(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)

            HStack {
                Text(value)
                    .font(.system(size: 13, weight: .regular))

                Spacer()

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                }, label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.231, green: 0.510, blue: 0.980))
                })
            }
            .padding(10)
            .background(Color(red: 0.110, green: 0.110, blue: 0.122))
            .cornerRadius(6)
        }
        .padding(12)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .cornerRadius(10)
    }

    private func aboutLink(_ label: String, icon: String) -> some View {
        Button(action: {}, label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))

                Text(label)
                    .font(.system(size: 13, weight: .regular))

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(Color(red: 0.231, green: 0.510, blue: 0.980))
            .padding(10)
            .background(Color(red: 0.110, green: 0.110, blue: 0.122))
            .cornerRadius(6)
        })
    }
}

#Preview {
    SettingsView()
}
