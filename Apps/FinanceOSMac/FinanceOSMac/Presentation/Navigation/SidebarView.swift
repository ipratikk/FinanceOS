import FinanceCore
import FinanceUI
import SwiftUI

struct SidebarView: View {
    @Environment(AppNavigator.self) private var navigator

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandHeader
            searchInput

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    FDSSidebarSectionHeader("Overview")
                    sidebarItem(.dashboard, shortcut: "⌘1")
                    sidebarItem(.analytics, shortcut: "⌘2")

                    FDSSidebarSectionHeader("Money")
                    sidebarItem(.accounts, shortcut: "⌘3")
                    sidebarItem(.cards, shortcut: "⌘4")
                    sidebarItem(.transactions, shortcut: "⌘5")

                    FDSSidebarSectionHeader("Manage")
                    sidebarItem(.banks, shortcut: "⌘6")
                    sidebarItem(.settings, shortcut: "⌘7")
                }
                .padding(.horizontal, 8)
            }

            Spacer()

            footerImport
        }
        .frame(minWidth: DesignTokens.Layout.sidebarWidth, idealWidth: DesignTokens.Layout.sidebarWidth, maxWidth: 240)
        .background(.regularMaterial)
        .colorScheme(.dark)
    }

    private var brandHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.xs)
                    .fill(DesignTokens.System.orange)
                    .frame(width: AppSpacing.xxl, height: AppSpacing.xxl)

                VStack(spacing: 3) {
                    Triangle().fill(DesignTokens.Text.primary).frame(height: 3)
                    Triangle().fill(DesignTokens.Text.primary).frame(height: 3)
                    Triangle().fill(DesignTokens.Text.primary).frame(height: 3)
                }
                .frame(width: 18, height: 18)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("FinanceOS")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignTokens.Text.primary)

                Text("Personal · INR")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(DesignTokens.Text.tertiary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private var searchInput: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignTokens.Text.tertiary)

            FDSTextInput("Find anything…", text: .constant(""), style: .labelSmall)

            Text("⌘K")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(DesignTokens.Text.tertiary)
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(DesignTokens.Background.inputWell)
        .cornerRadius(AppRadius.lg)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var footerImport: some View {
        VStack(spacing: 8) {
            Divider().opacity(DesignTokens.Opacity.low)

            Button(action: { navigator.navigate(to: .importStatement) }, label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(DesignTokens.System.orange.opacity(DesignTokens.Opacity.low))

                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DesignTokens.System.orange)
                    }
                    .frame(width: 28, height: 28)

                    Text("Import statement")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignTokens.Text.primary)

                    Spacer()

                    Text("⌘I")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(DesignTokens.Text.tertiary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            })
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                Circle()
                    .fill(DesignTokens.System.green)
                    .frame(width: 6, height: 6)
                    .shadow(color: DesignTokens.System.green.opacity(DesignTokens.Opacity.high), radius: 3)

                Text("Database healthy · 2,148 txns")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(DesignTokens.Text.tertiary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private func sidebarItem(_ item: NavigationItem, shortcut: String) -> some View {
        HStack(spacing: 8) {
            FDSSidebarItem(
                item.label,
                symbol: item.icon,
                isSelected: navigator.sidebarSelection == item,
                action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        navigator.navigate(to: item)
                    }
                }
            )

            if navigator.sidebarSelection == item {
                Spacer()
                Text(shortcut)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(DesignTokens.Text.tertiary)
            }
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    SidebarView()
        .environment(AppNavigator())
        .frame(width: DesignTokens.Layout.sidebarWidth, height: 600)
}
