import FinanceCore
import FinanceUI
import SwiftUI

struct SidebarView: View {
    @Environment(AppNavigator.self) private var navigator

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandHeader

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 1) {
                    FDSSidebarSectionHeader("Overview")
                    sidebarItem(.dashboard)
                    sidebarItem(.analytics)

                    FDSSidebarSectionHeader("Money")
                    sidebarItem(.accounts)
                    sidebarItem(.cards)
                    sidebarItem(.transactions)

                    FDSSidebarSectionHeader("Manage")
                    sidebarItem(.banks)
                    sidebarItem(.settings)
                }
                .padding(.horizontal, AppSpacing.compact)
            }

            footerImport
        }
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 240)
        .background(.regularMaterial)
    }

    private var brandHeader: some View {
        HStack(spacing: AppSpacing.compact) {
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(AppColors.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: 0) {
                Text("FinanceOS")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Personal")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
    }

    private var footerImport: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.3)

            Button(action: { navigator.navigate(to: .importStatement) }) {
                HStack(spacing: AppSpacing.compact) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.accent)
                        .frame(width: 18)

                    Text("Import Statement")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.compact)
                .padding(.vertical, AppSpacing.compact)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.compact)
            .padding(.vertical, AppSpacing.compact)
        }
    }

    private func sidebarItem(_ item: NavigationItem) -> some View {
        FDSSidebarItem(
            item.label,
            symbol: item.icon,
            isSelected: navigator.sidebarSelection == item,
            action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    navigator.navigate(to: item)
                }
            }
        )
    }
}

#Preview {
    SidebarView()
        .environment(AppNavigator())
        .frame(width: 220, height: 600)
}
