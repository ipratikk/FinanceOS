import FinanceCore
import FinanceUI
import SwiftUI

struct ToastPresenterView: View {
    let presenter: ToastPresenter
    private let notificationWidth: CGFloat = 360

    var body: some View {
        if let config = presenter.currentToast {
            ZStack(alignment: alignmentForConfig(config)) {
                toastView(for: config)
                    .frame(maxWidth: config.fullWidth ? .infinity : notificationWidth)
                    .padding(.horizontal, config.fullWidth ? 0 : AppSpacing.md)
                    .padding(.vertical, AppSpacing.md)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignmentForConfig(config))
        }
    }

    private func toastView(for config: ToastConfig) -> some View {
        HStack(alignment: config.verticalAlignment, spacing: AppSpacing.md) {
            Image(systemName: iconName(for: config.type))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Text(config.message)
                .font(AppTypography.labelMedium)
                .foregroundColor(.white)
                .lineLimit(3)

            Spacer()

            Button(action: { presenter.dismiss() }, label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            })
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(backgroundColor(for: config.type))
        .cornerRadius(AppRadius.sm)
        .transition(.move(edge: config.position == .top ? .top : .bottom).combined(with: .opacity))
    }

    private func alignmentForConfig(_ config: ToastConfig) -> Alignment {
        switch config.horizontalAlignment {
        case .leading:
            config.position == .top ? .topLeading : .bottomLeading
        case .trailing:
            config.position == .top ? .topTrailing : .bottomTrailing
        default:
            config.position == .top ? .topLeading : .bottomLeading
        }
    }

    private func iconName(for type: ToastType) -> String {
        switch type {
        case .success: "checkmark.circle.fill"
        case .error: "xmark.circle.fill"
        case .warning: "exclamationmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }

    private func backgroundColor(for type: ToastType) -> Color {
        switch type {
        case .success: Color(red: 0.2, green: 0.5, blue: 0.2)
        case .error: Color(red: 0.6, green: 0.2, blue: 0.2)
        case .warning: Color(red: 0.7, green: 0.45, blue: 0.1)
        case .info: Color(red: 0.2, green: 0.4, blue: 0.6)
        }
    }
}
