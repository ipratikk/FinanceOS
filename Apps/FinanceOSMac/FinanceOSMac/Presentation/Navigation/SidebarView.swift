import FinanceCore
import FinanceUI
import SwiftUI

struct SidebarView: View {
    @Environment(AppNavigator.self) private var navigator
    @Namespace private var selectionNamespace

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                FDSLabel("FinanceOS", style: .headingMedium)
                FDSLabel("Financial OS", style: .labelSmall)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.md)
            .background(.ultraThinMaterial)
            .overlay(
                Divider(),
                alignment: .bottom
            )

            // Navigation
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(NavigationItem.allCases, id: \.self) { item in
                        navigationButton(item)
                    }
                }
                .padding(.vertical, AppSpacing.md)
                .padding(.horizontal, AppSpacing.sm)
            }

            Spacer()

            // Footer
            Button(action: { navigator.navigate(to: .importStatement) }, label: {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.accent)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(AppSpacing.md)
                    .contentShape(Rectangle())
            })
            .buttonStyle(.plain)
            .background(.ultraThinMaterial)
            .overlay(
                Divider(),
                alignment: .top
            )
        }
        .background(AppColors.base)
        .frame(minWidth: 180)
    }

    private func navigationButton(_ item: NavigationItem) -> some View {
        Button(action: { withAnimation(AppAnimation.selection) { navigator.navigate(to: item) } }) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: item.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 16)

                Text(item.label)
                    .bodyLarge()

                Spacer()
            }
            .foregroundColor(navigator.sidebarSelection == item ? AppColors.textPrimary : AppColors.textTertiary)
            .padding(.vertical, AppSpacing.compact)
            .padding(.horizontal, AppSpacing.sm)
            .background(
                Group {
                    if navigator.sidebarSelection == item {
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.sm)
                                    .stroke(AppColors.borderGlass, lineWidth: 0.5)
                            )
                            .matchedGeometryEffect(id: "selection", in: selectionNamespace)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let navigator = AppNavigator()
    return SidebarView()
        .environment(navigator)
}
