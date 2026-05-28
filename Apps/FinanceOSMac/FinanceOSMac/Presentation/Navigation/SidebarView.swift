import FinanceCore
import FinanceUI
import SwiftUI

struct SidebarView: View {
    @Environment(AppNavigator.self) private var navigator

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandHeader
            searchInput

            List {
                Section {
                    sidebarItem(.dashboard, shortcut: "⌘1")
                    sidebarItem(.analytics, shortcut: "⌘2")
                } header: {
                    FDSSidebarSectionHeader("Overview")
                }

                Section {
                    sidebarItem(.accounts, shortcut: "⌘3")
                    sidebarItem(.cards, shortcut: "⌘4")
                    sidebarItem(.transactions, shortcut: "⌘5")
                } header: {
                    FDSSidebarSectionHeader("Money")
                }

                Section {
                    sidebarItem(.banks, shortcut: "⌘6")
                    sidebarItem(.settings, shortcut: "⌘7")
                } header: {
                    FDSSidebarSectionHeader("Manage")
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footerImport
        }
        .frame(minWidth: AppSpacing.Layout.sidebarWidth, idealWidth: AppSpacing.Layout.sidebarWidth)
        .colorScheme(.dark)
    }

    private var brandHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.xs)
                    .fill(AppColors.System.orange)
                    .frame(width: AppSpacing.xxl, height: AppSpacing.xxl)

                VStack(spacing: 3) {
                    Triangle().fill(AppColors.Text.primary).frame(height: 3)
                    Triangle().fill(AppColors.Text.primary).frame(height: 3)
                    Triangle().fill(AppColors.Text.primary).frame(height: 3)
                }
                .frame(width: 18, height: 18)
            }

            VStack(alignment: .leading, spacing: 2) {
                FDSLabel("FinanceOS")
                    .font(AppTypography.bodySmSemibold)
                    .foregroundColor(AppColors.Text.primary)

                FDSLabel("Personal · INR")
                    .font(AppTypography.captionSm)
                    .foregroundColor(AppColors.Text.tertiary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private var searchInput: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(AppTypography.captionSmSemibold)
                .foregroundColor(AppColors.Text.tertiary)

            FDSTextInput("Find anything…", text: .constant(""), style: .labelSmall)

            FDSLabel("⌘K")
                .font(AppTypography.captionSmMedium)
                .foregroundColor(AppColors.Text.tertiary)
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(AppColors.Glass.inputWell)
        .cornerRadius(AppRadius.lg)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var footerImport: some View {
        VStack(spacing: 8) {
            Divider().opacity(AppColors.Opacity.low)

            Button(action: { navigator.navigate(to: .importStatement) }, label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AppColors.System.orange.opacity(AppColors.Opacity.low))

                        Image(systemName: "arrow.down.doc")
                            .font(AppTypography.captionSmSemibold)
                            .foregroundColor(AppColors.System.orange)
                    }
                    .frame(width: 28, height: 28)

                    FDSLabel("Import statement")
                        .font(AppTypography.captionSmSemibold)
                        .foregroundColor(AppColors.Text.primary)

                    Spacer()

                    FDSLabel("⌘I")
                        .font(AppTypography.captionSmMedium)
                        .foregroundColor(AppColors.Text.tertiary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            })
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                Circle()
                    .fill(AppColors.System.green)
                    .frame(width: 6, height: 6)
                    .shadow(color: AppColors.System.green.opacity(AppColors.Opacity.high), radius: 3)

                FDSLabel("Database healthy · 2,148 txns")
                    .font(AppTypography.captionSm)
                    .foregroundColor(AppColors.Text.tertiary)

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
                FDSLabel(shortcut)
                    .font(AppTypography.captionSmMedium)
                    .foregroundColor(AppColors.Text.tertiary)
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
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
        .frame(width: AppSpacing.Layout.sidebarWidth, height: 600)
}
